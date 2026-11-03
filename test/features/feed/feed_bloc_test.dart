import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';

const _debounce = Duration(milliseconds: 20);
const _afterDebounce = Duration(milliseconds: 60);

void main() {
  late MockGifRepository repository;

  setUpAll(registerTestFallbacks);

  setUp(() => repository = MockGifRepository());

  FeedBloc buildBloc() => FeedBloc(repository: repository, debounce: _debounce);

  void stubTrending(Result<GifPage> Function(int offset) answer) {
    when(
      () => repository.trending(
        offset: any(named: 'offset'),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer(
      (invocation) async => answer(invocation.namedArguments[#offset] as int),
    );
  }

  void stubSearch(Result<GifPage> Function(String query, int offset) answer) {
    when(
      () => repository.search(
        any(),
        offset: any(named: 'offset'),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer(
      (invocation) async => answer(
        invocation.positionalArguments.first as String,
        invocation.namedArguments[#offset] as int,
      ),
    );
  }

  final firstPage = makePage(makeGifs([1, 2, 3]), count: 3);
  final loadedTrending = FeedState(
    items: firstPage.items,
    status: FeedStatus.success,
    nextOffset: 3,
  );

  group('FeedStarted', () {
    blocTest<FeedBloc, FeedState>(
      'loads trending when the query is empty',
      setUp: () => stubTrending((_) => Success(firstPage)),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedStarted()),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        loadedTrending,
      ],
      verify: (_) => verify(
        () => repository.trending(
          offset: 0,
          cancellation: any(named: 'cancellation'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'emits failure when the first page fails',
      setUp: () => stubTrending((_) => const Err(NoConnectionFailure())),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedStarted()),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        const FeedState(
          status: FeedStatus.failure,
          failure: NoConnectionFailure(),
        ),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'marks the end when total_count is reached',
      setUp: () => stubTrending(
        (_) => Success(makePage(makeGifs([1, 2]), totalCount: 2)),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedStarted()),
      skip: 1,
      expect: () => [
        isA<FeedState>().having((s) => s.hasReachedEnd, 'hasReachedEnd', true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'removes duplicates within the first page',
      setUp: () => stubTrending(
        (_) => Success(
          makePage([
            ...makeGifs([1, 2]),
            makeGif('g1'),
          ]),
        ),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedStarted()),
      skip: 1,
      expect: () => [
        isA<FeedState>().having((s) => s.items.map((gif) => gif.id), 'ids', [
          'g1',
          'g2',
        ]),
      ],
    );
  });

  group('search queries', () {
    blocTest<FeedBloc, FeedState>(
      'debounces rapid typing into one request for the last query',
      setUp: () => stubSearch((query, _) => Success(firstPage)),
      build: buildBloc,
      act: (bloc) async {
        bloc
          ..add(const FeedQueryChanged('c'))
          ..add(const FeedQueryChanged('ca'))
          ..add(const FeedQueryChanged('cat'))
          ..add(const FeedQueryChanged('cats '));
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [
        const FeedState(query: 'cats', status: FeedStatus.loading),
        FeedState(
          query: 'cats',
          items: firstPage.items,
          status: FeedStatus.success,
          nextOffset: 3,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.search(
            'cats',
            offset: 0,
            cancellation: any(named: 'cancellation'),
          ),
        ).called(1);
        verifyNoMoreInteractions(repository);
      },
    );

    blocTest<FeedBloc, FeedState>(
      'submits immediately without waiting for the debounce',
      setUp: () => stubSearch((query, _) => Success(firstPage)),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedQuerySubmitted('dogs')),
      wait: Duration.zero,
      expect: () => [
        const FeedState(query: 'dogs', status: FeedStatus.loading),
        isA<FeedState>().having((s) => s.query, 'query', 'dogs'),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'ignores a debounced query equal to the one already loaded',
      setUp: () => stubSearch((query, _) => Success(firstPage)),
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FeedQuerySubmitted('cats'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FeedQueryChanged('cats'));
        await Future<void>.delayed(_afterDebounce);
      },
      skip: 2,
      expect: () => <FeedState>[],
      verify: (_) => verify(
        () => repository.search(
          'cats',
          offset: 0,
          cancellation: any(named: 'cancellation'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'clearing the query loads trending again',
      setUp: () {
        stubSearch((query, _) => Success(makePage(makeGifs([9]))));
        stubTrending((_) => Success(firstPage));
      },
      seed: () => FeedState(
        query: 'cats',
        items: makeGifs([9]),
        status: FeedStatus.success,
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedQuerySubmitted('')),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        loadedTrending,
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'ignores the response of an older query',
      setUp: () {
        final slowCats = Completer<Result<GifPage>>();
        when(
          () => repository.search(
            'cats',
            offset: any(named: 'offset'),
            cancellation: any(named: 'cancellation'),
          ),
        ).thenAnswer((_) => slowCats.future);
        when(
          () => repository.search(
            'dogs',
            offset: any(named: 'offset'),
            cancellation: any(named: 'cancellation'),
          ),
        ).thenAnswer((_) async {
          slowCats.complete(Success(makePage(makeGifs([1], prefix: 'cat'))));
          return Success(makePage(makeGifs([1], prefix: 'dog')));
        });
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FeedQuerySubmitted('cats'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FeedQuerySubmitted('dogs'));
      },
      wait: _afterDebounce,
      expect: () => [
        const FeedState(query: 'cats', status: FeedStatus.loading),
        const FeedState(query: 'dogs', status: FeedStatus.loading),
        FeedState(
          query: 'dogs',
          items: makeGifs([1], prefix: 'dog'),
          status: FeedStatus.success,
          nextOffset: 1,
        ),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'cancels the in-flight request of an older query',
      setUp: () {
        when(
          () => repository.search(
            'cats',
            offset: any(named: 'offset'),
            cancellation: any(named: 'cancellation'),
          ),
        ).thenAnswer((_) => Completer<Result<GifPage>>().future);
        stubSearch((query, _) => Success(firstPage));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FeedQuerySubmitted('cats'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const FeedQuerySubmitted('dogs'));
      },
      wait: _afterDebounce,
      verify: (_) {
        final token =
            verify(
                  () => repository.search(
                    'cats',
                    offset: 0,
                    cancellation: captureAny(named: 'cancellation'),
                  ),
                ).captured.single
                as CancellationToken;
        expect(token.isCancelled, isTrue);
      },
    );
  });

  group('pagination', () {
    blocTest<FeedBloc, FeedState>(
      'appends the next page and removes duplicates',
      setUp: () => stubTrending(
        (offset) => Success(
          makePage([
            makeGif('g3'),
            ...makeGifs([4, 5]),
          ], offset: offset),
        ),
      ),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedNextPageRequested()),
      expect: () => [
        loadedTrending.copyWith(loadMore: LoadMoreStatus.loading),
        loadedTrending.copyWith(
          items: makeGifs([1, 2, 3, 4, 5]),
          nextOffset: 6,
        ),
      ],
      verify: (_) => verify(
        () => repository.trending(
          offset: 3,
          cancellation: any(named: 'cancellation'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'never runs two page loads at once',
      setUp: () => when(
        () => repository.trending(
          offset: any(named: 'offset'),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer((_) => Completer<Result<GifPage>>().future),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const FeedNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const FeedNextPageRequested())
          ..add(const FeedNextPageRequested());
      },
      expect: () => [loadedTrending.copyWith(loadMore: LoadMoreStatus.loading)],
      verify: (_) => verify(
        () => repository.trending(
          offset: any(named: 'offset'),
          cancellation: any(named: 'cancellation'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'stops at the GIPHY max offset',
      setUp: () => stubTrending(
        (offset) => Success(
          makePage(makeGifs([4]), offset: offset, count: 30, maxOffset: 30),
        ),
      ),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedNextPageRequested()),
      skip: 1,
      expect: () => [
        isA<FeedState>().having((s) => s.hasReachedEnd, 'hasReachedEnd', true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'does nothing after the end is reached',
      seed: () => loadedTrending.copyWith(hasReachedEnd: true),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedNextPageRequested()),
      expect: () => <FeedState>[],
      verify: (_) => verifyZeroInteractions(repository),
    );

    blocTest<FeedBloc, FeedState>(
      'keeps loaded items when the next page fails',
      setUp: () => stubTrending((_) => const Err(TimeoutFailure())),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedNextPageRequested()),
      expect: () => [
        loadedTrending.copyWith(loadMore: LoadMoreStatus.loading),
        loadedTrending.copyWith(
          loadMore: LoadMoreStatus.failure,
          loadMoreFailure: () => const TimeoutFailure(),
        ),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'does not auto-load more while a load-more failure is shown',
      seed: () => loadedTrending.copyWith(
        loadMore: LoadMoreStatus.failure,
        loadMoreFailure: () => const TimeoutFailure(),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedNextPageRequested()),
      expect: () => <FeedState>[],
    );

    blocTest<FeedBloc, FeedState>(
      'retries a failed load-more',
      setUp: () => stubTrending(
        (offset) => Success(makePage(makeGifs([4]), offset: offset)),
      ),
      seed: () => loadedTrending.copyWith(
        loadMore: LoadMoreStatus.failure,
        loadMoreFailure: () => const TimeoutFailure(),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedLoadMoreRetried()),
      expect: () => [
        loadedTrending.copyWith(loadMore: LoadMoreStatus.loading),
        loadedTrending.copyWith(items: makeGifs([1, 2, 3, 4]), nextOffset: 4),
      ],
    );
  });

  group('retry and refresh', () {
    blocTest<FeedBloc, FeedState>(
      'retry reloads the first page after a failure',
      setUp: () => stubTrending((_) => Success(firstPage)),
      seed: () => const FeedState(
        status: FeedStatus.failure,
        failure: ServerFailure(500),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedRetried()),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        loadedTrending,
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'refresh keeps current items visible and reloads from offset 0',
      setUp: () => stubTrending((_) => Success(makePage(makeGifs([7])))),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedRefreshed()),
      expect: () => [
        loadedTrending.copyWith(status: FeedStatus.loading),
        FeedState(
          items: makeGifs([7]),
          status: FeedStatus.success,
          nextOffset: 1,
        ),
      ],
      verify: (_) => verify(
        () => repository.trending(
          offset: 0,
          cancellation: any(named: 'cancellation'),
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'a failed refresh keeps the loaded items',
      setUp: () => stubTrending((_) => const Err(RateLimitedFailure())),
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedRefreshed()),
      skip: 1,
      expect: () => [
        loadedTrending.copyWith(
          status: FeedStatus.failure,
          failure: () => const RateLimitedFailure(),
        ),
      ],
    );
  });

  group('FeedReconnected', () {
    blocTest<FeedBloc, FeedState>(
      'reloads the first page after a connection failure',
      setUp: () => stubTrending((_) => Success(firstPage)),
      seed: () => const FeedState(
        status: FeedStatus.failure,
        failure: NoConnectionFailure(),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedReconnected()),
      expect: () => [
        const FeedState(status: FeedStatus.loading),
        loadedTrending,
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'retries a load-more that failed with a timeout',
      setUp: () => stubTrending(
        (offset) => Success(makePage(makeGifs([4]), offset: offset)),
      ),
      seed: () => loadedTrending.copyWith(
        loadMore: LoadMoreStatus.failure,
        loadMoreFailure: () => const TimeoutFailure(),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedReconnected()),
      skip: 1,
      expect: () => [
        loadedTrending.copyWith(items: makeGifs([1, 2, 3, 4]), nextOffset: 4),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'does not retry failures unrelated to connectivity',
      seed: () => const FeedState(
        status: FeedStatus.failure,
        failure: UnauthorizedFailure(),
      ),
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedReconnected()),
      expect: () => <FeedState>[],
      verify: (_) => verifyZeroInteractions(repository),
    );

    blocTest<FeedBloc, FeedState>(
      'does nothing when the feed is healthy',
      seed: () => loadedTrending,
      build: buildBloc,
      act: (bloc) => bloc.add(const FeedReconnected()),
      expect: () => <FeedState>[],
    );
  });
}
