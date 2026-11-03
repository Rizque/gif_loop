import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/config/giphy_config.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/data/gif_repository_impl.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixture.dart';

class _MockDio extends Mock implements Dio;

void main() {
  late _MockDio dio;
  late GifRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(CancelToken()));

  setUp(() {
    dio = _MockDio();
    repository = GifRepositoryImpl(GiphyApi(dio));
  });

  void stubGet(Map<String, dynamic> body) {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (invocation) async => Response(
        requestOptions: RequestOptions(
          path: invocation.positionalArguments.first as String,
        ),
        data: body,
        statusCode: 200,
      ),
    );
  }

  void stubGetError(DioException exception) {
    when(
      () => dio.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenThrow(exception);
  }

  ({String path, Map<String, dynamic> query, CancelToken? token})
  capturedGet() {
    final captured = verify(
      () => dio.get<Map<String, dynamic>>(
        captureAny(),
        queryParameters: captureAny(named: 'queryParameters'),
        cancelToken: captureAny(named: 'cancelToken'),
      ),
    ).captured;
    return (
      path: captured[0] as String,
      query: captured[1] as Map<String, dynamic>,
      token: captured[2] as CancelToken?,
    );
  }

  group('trending', () {
    test('calls gifs/trending with paging and rating params', () async {
      stubGet(fixture('trending_page.json'));

      await repository.trending(offset: 30);

      final call = capturedGet();
      expect(call.path, 'gifs/trending');
      expect(call.query, {
        'offset': 30,
        'limit': GiphyConfig.pageSize,
        'rating': GiphyConfig.rating,
      });
    });

    test('returns a page with trending max offset', () async {
      stubGet(fixture('trending_page.json'));

      final result = await repository.trending(offset: 0);

      final page = (result as Success<GifPage>).value;
      expect(page.items.map((gif) => gif.id), [
        '3o7TKSjRrfIPjeiVyM',
        'l0HlvtIPzPdt2usKs',
      ]);
      expect(page.nextOffset, 2);
      expect(page.totalCount, 120);
      expect(page.maxOffset, GiphyConfig.maxTrendingOffset);
      expect(page.hasMore, isTrue);
    });

    test('drops unusable items but keeps GIPHY count for paging', () async {
      stubGet(fixture('malformed_items_page.json'));

      final page =
          (await repository.trending(offset: 0) as Success<GifPage>).value;

      expect(page.items.map((gif) => gif.id), ['onlyOriginal']);
      expect(page.count, 4);
    });

    test('returns ServerFailure for a synthetic response', () async {
      stubGet(fixture('synthetic_response.json'));

      final result = await repository.trending(offset: 0);

      expect((result as Err<GifPage>).failure, const ServerFailure(200));
    });

    test('maps Dio errors to failures', () async {
      stubGetError(
        DioException.connectionError(
          requestOptions: RequestOptions(),
          reason: 'offline',
        ),
      );

      final result = await repository.trending(offset: 0);

      expect((result as Err<GifPage>).failure, const NoConnectionFailure());
    });

    test('cancels the HTTP request when the token is cancelled', () async {
      stubGet(fixture('trending_page.json'));
      final cancellation = CancellationToken();

      await repository.trending(offset: 0, cancellation: cancellation);
      cancellation.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(capturedGet().token!.isCancelled, isTrue);
    });
  });

  group('search', () {
    test('calls gifs/search with query, language and rating', () async {
      stubGet(fixture('trending_page.json'));

      await repository.search('cats', offset: 5);

      final call = capturedGet();
      expect(call.path, 'gifs/search');
      expect(call.query, {
        'q': 'cats',
        'offset': 5,
        'limit': GiphyConfig.pageSize,
        'rating': GiphyConfig.rating,
        'lang': GiphyConfig.language,
      });
    });

    test('returns a page with search max offset', () async {
      stubGet(fixture('trending_page.json'));

      final result = await repository.search('cats', offset: 0);

      final page = (result as Success<GifPage>).value;
      expect(page.maxOffset, GiphyConfig.maxSearchOffset);
    });

    test('maps 429 to RateLimitedFailure', () async {
      final options = RequestOptions();
      stubGetError(
        DioException.badResponse(
          statusCode: 429,
          requestOptions: options,
          response: Response<void>(requestOptions: options, statusCode: 429),
        ),
      );

      final result = await repository.search('cats', offset: 0);

      expect((result as Err<GifPage>).failure, const RateLimitedFailure());
    });
  });

  group('gifById', () {
    test('calls gifs/{id} and returns the GIF', () async {
      stubGet(fixture('gif_by_id.json'));

      final result = await repository.gifById('3o7TKSjRrfIPjeiVyM');

      expect(capturedGet().path, 'gifs/3o7TKSjRrfIPjeiVyM');
      expect((result as Success<Gif>).value.id, '3o7TKSjRrfIPjeiVyM');
    });

    test('returns NotFoundFailure when data is empty', () async {
      stubGet(const {'data': <Object>[], 'meta': <String, Object>{}});

      final result = await repository.gifById('missing');

      expect((result as Err<Gif>).failure, const NotFoundFailure());
    });
  });
}
