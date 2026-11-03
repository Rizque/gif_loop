import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/gifs/data/gif_repository_impl.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

class _MockGiphyApi extends Mock implements GiphyApi;

void main() {
  group('GifRepositoryImpl.trendingSearches', () {
    late _MockGiphyApi api;
    late GifRepositoryImpl repository;

    setUp(() {
      api = _MockGiphyApi();
      repository = GifRepositoryImpl(api);
    });

    test('loads the terms once per session', () async {
      when(api.trendingSearches).thenAnswer((_) async => ['cats', 'dogs']);

      final first = await repository.trendingSearches();
      final second = await repository.trendingSearches();

      expect((first as Success<List<String>>).value, ['cats', 'dogs']);
      expect((second as Success<List<String>>).value, ['cats', 'dogs']);
      verify(api.trendingSearches).called(1);
    });

    test('does not cache a failure', () async {
      when(api.trendingSearches).thenThrow(
        DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'offline',
        ),
      );

      final result = await repository.trendingSearches();
      expect(
        (result as Err<List<String>>).failure,
        const NoConnectionFailure(),
      );

      when(api.trendingSearches).thenAnswer((_) async => ['cats']);
      expect(await repository.trendingSearches(), isA<Success<List<String>>>());
    });
  });

  group('TrendingSearchesCubit', () {
    late MockGifRepository repository;

    setUp(() => repository = MockGifRepository());

    blocTest<TrendingSearchesCubit, List<String>>(
      'shows at most ten terms',
      setUp: () => when(repository.trendingSearches).thenAnswer(
        (_) async => Success([for (var i = 0; i < 15; i++) 'term $i']),
      ),
      build: () => TrendingSearchesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [hasLength(TrendingSearchesCubit.maxTerms)],
    );

    blocTest<TrendingSearchesCubit, List<String>>(
      'stays empty when loading fails',
      setUp: () =>
          when(repository.trendingSearches)
              .thenAnswer((_) async => const Err(TimeoutFailure())),
      build: () => TrendingSearchesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => <List<String>>[],
    );
  });
}
