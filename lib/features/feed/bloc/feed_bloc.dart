import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:rxdart/rxdart.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  new({required this._repository, Duration debounce = defaultDebounce})
    : super(const FeedState()) {
    on<FeedStarted>(_onStarted, transformer: droppable());
    on<FeedQueryEvent>(_onQuery, transformer: _debounceQueries(debounce));
    on<FeedNextPageRequested>(_onNextPageRequested, transformer: droppable());
    on<FeedLoadMoreRetried>(_onLoadMoreRetried, transformer: droppable());
    on<FeedRefreshed>(_onRefreshed, transformer: restartable());
    on<FeedRetried>(_onRetried, transformer: restartable());
    on<FeedReconnected>(_onReconnected, transformer: droppable());
  }

  static const Duration defaultDebounce = Duration(milliseconds: 400);

  final GifRepository _repository;
  CancellationToken? _activeRequest;

  // Typing is debounced, a submit goes through immediately, and switchMap
  // drops the handler of any older query (restartable).
  static EventTransformer<FeedQueryEvent> _debounceQueries(Duration debounce) =>
      (events, mapper) => events
          .switchMap(
            (event) => event is FeedQuerySubmitted
                ? Stream.value(event)
                : Rx.timer(event, debounce),
          )
          .switchMap(mapper);

  Future<void> _onStarted(FeedStarted event, Emitter<FeedState> emit) async {
    if (state.status != FeedStatus.initial) return;
    await _loadFirstPage(state.query, emit, keepItems: false);
  }

  Future<void> _onQuery(FeedQueryEvent event, Emitter<FeedState> emit) async {
    final query = event.query.trim();
    final isSameQuery =
        query == state.query &&
        (state.status == FeedStatus.loading ||
            state.status == FeedStatus.success);
    if (isSameQuery) return;
    await _loadFirstPage(query, emit, keepItems: false);
  }

  Future<void> _onRefreshed(FeedRefreshed event, Emitter<FeedState> emit) =>
      _loadFirstPage(state.query, emit, keepItems: true);

  Future<void> _onRetried(FeedRetried event, Emitter<FeedState> emit) =>
      _loadFirstPage(state.query, emit, keepItems: false);

  Future<void> _onNextPageRequested(
    FeedNextPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (!state.canLoadMore) return;
    await _loadNextPage(emit);
  }

  Future<void> _onLoadMoreRetried(
    FeedLoadMoreRetried event,
    Emitter<FeedState> emit,
  ) async {
    if (state.loadMore != LoadMoreStatus.failure) return;
    await _loadNextPage(emit);
  }

  Future<void> _onReconnected(
    FeedReconnected event,
    Emitter<FeedState> emit,
  ) async {
    if (state.status == FeedStatus.failure &&
        (state.failure?.isTransient ?? false)) {
      await _loadFirstPage(state.query, emit, keepItems: true);
    } else if (state.loadMore == LoadMoreStatus.failure &&
        (state.loadMoreFailure?.isTransient ?? false)) {
      await _loadNextPage(emit);
    }
  }

  Future<void> _loadFirstPage(
    String query,
    Emitter<FeedState> emit, {
    required bool keepItems,
  }) async {
    final request = _startRequest();
    emit(
      keepItems
          ? state.copyWith(
              status: FeedStatus.loading,
              loadMore: LoadMoreStatus.idle,
              failure: () => null,
              loadMoreFailure: () => null,
            )
          : FeedState(query: query, status: FeedStatus.loading),
    );
    final result = await _fetch(query, 0, request);
    if (request.isCancelled) return;
    switch (result) {
      case Success(value: final page):
        emit(
          FeedState(
            query: query,
            items: _appendUnique(const [], page.items),
            status: FeedStatus.success,
            hasReachedEnd: !page.hasMore,
            nextOffset: page.nextOffset,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(status: FeedStatus.failure, failure: () => failure),
        );
    }
  }

  Future<void> _loadNextPage(Emitter<FeedState> emit) async {
    final request = _startRequest();
    emit(
      state.copyWith(
        loadMore: LoadMoreStatus.loading,
        loadMoreFailure: () => null,
      ),
    );
    final result = await _fetch(state.query, state.nextOffset, request);
    if (request.isCancelled) return;
    switch (result) {
      case Success(value: final page):
        emit(
          state.copyWith(
            items: _appendUnique(state.items, page.items),
            loadMore: LoadMoreStatus.idle,
            hasReachedEnd: !page.hasMore,
            nextOffset: page.nextOffset,
          ),
        );
      case Err(:final failure):
        emit(
          state.copyWith(
            loadMore: LoadMoreStatus.failure,
            loadMoreFailure: () => failure,
          ),
        );
    }
  }

  Future<Result<GifPage>> _fetch(
    String query,
    int offset,
    CancellationToken request,
  ) => query.isEmpty
      ? _repository.trending(offset: offset, cancellation: request)
      : _repository.search(query, offset: offset, cancellation: request);

  CancellationToken _startRequest() {
    _activeRequest?.cancel();
    return _activeRequest = CancellationToken();
  }

  // GIPHY can return the same GIF on several pages.
  static List<Gif> _appendUnique(List<Gif> current, List<Gif> incoming) {
    final seenIds = {for (final gif in current) gif.id};
    return [...current, ...incoming.where((gif) => seenIds.add(gif.id))];
  }

  @override
  Future<void> close() {
    _activeRequest?.cancel();
    return super.close();
  }
}
