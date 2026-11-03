import 'dart:async';
import 'dart:collection';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/search/cubit/suggestions_state.dart';

class SuggestionsCubit extends Cubit<SuggestionsState> {
  new({required this._repository, this._debounce = defaultDebounce})
    : super(const SuggestionsState());

  static const Duration defaultDebounce = Duration(milliseconds: 300);
  static const int minQueryLength = 2;
  static const int maxSuggestions = 6;
  static const int cacheSize = 20;

  final GifRepository _repository;
  final Duration _debounce;
  final LinkedHashMap<String, List<String>> _cache = LinkedHashMap();
  Timer? _debounceTimer;
  CancellationToken? _request;

  void queryChanged(String text) {
    final query = text.trim();
    _cancelPending();
    if (query.length < minQueryLength) {
      emit(const SuggestionsState());
      return;
    }
    final cached = _cache[query.toLowerCase()];
    if (cached != null) {
      emit(SuggestionsState(query: query, suggestions: cached));
      return;
    }
    _debounceTimer = Timer(_debounce, () => unawaited(_load(query)));
  }

  void clear() {
    _cancelPending();
    emit(const SuggestionsState());
  }

  // Suggestions are a convenience, so failures just show nothing.
  Future<void> _load(String query) async {
    final request = _request = CancellationToken();
    final result = await _repository.searchSuggestions(
      query,
      limit: maxSuggestions,
      cancellation: request,
    );
    if (request.isCancelled || isClosed) return;
    switch (result) {
      case Success(value: final terms):
        final suggestions = terms.take(maxSuggestions).toList();
        _remember(query.toLowerCase(), suggestions);
        emit(SuggestionsState(query: query, suggestions: suggestions));
      case Err():
        emit(SuggestionsState(query: query));
    }
  }

  void _remember(String key, List<String> suggestions) {
    _cache
      ..remove(key)
      ..[key] = suggestions;
    if (_cache.length > cacheSize) _cache.remove(_cache.keys.first);
  }

  void _cancelPending() {
    _debounceTimer?.cancel();
    _request?.cancel();
  }

  @override
  Future<void> close() {
    _cancelPending();
    return super.close();
  }
}
