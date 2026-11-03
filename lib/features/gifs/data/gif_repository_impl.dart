import 'dart:async';

import 'package:dio/dio.dart';
import 'package:gif_loop/core/config/giphy_config.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_mapper.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/data/dto/gif_list_response_dto.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';

class GifRepositoryImpl implements GifRepository {
  const new(this._api);

  final GiphyApi _api;

  @override
  Future<Result<GifPage>> trending({
    required int offset,
    CancellationToken? cancellation,
  }) => _guard(cancellation, (cancelToken) async {
    final response = await _api.trending(
      offset: offset,
      limit: GiphyConfig.pageSize,
      rating: ContentRating.pg.apiValue,
      cancelToken: cancelToken,
    );
    return _toPage(response, offset, GiphyConfig.maxTrendingOffset);
  });

  @override
  Future<Result<GifPage>> search(
    String query, {
    required int offset,
    int limit = GiphyConfig.pageSize,
    ContentRating rating = ContentRating.pg,
    CancellationToken? cancellation,
  }) => _guard(cancellation, (cancelToken) async {
    final response = await _api.search(
      query: query,
      offset: offset,
      limit: limit,
      rating: rating.apiValue,
      cancelToken: cancelToken,
    );
    return _toPage(response, offset, GiphyConfig.maxSearchOffset);
  });

  @override
  Future<Result<Gif>> gifById(String id) => _guard(null, (_) async {
    final gif = (await _api.gifById(id))?.toDomain();
    return gif == null ? const Err(NotFoundFailure()) : Success(gif);
  });

  Result<GifPage> _toPage(
    GifListResponseDto response,
    int requestedOffset,
    int maxOffset,
  ) {
    if (response.isSynthetic) return Err(ServerFailure(response.status));
    final offset = response.offset ?? requestedOffset;
    final count = response.count ?? response.data.length;
    return Success(
      GifPage(
        items: response.data.map((dto) => dto.toDomain()).nonNulls.toList(),
        offset: offset,
        count: count,
        totalCount: response.totalCount ?? offset + count,
        maxOffset: maxOffset,
      ),
    );
  }

  Future<Result<T>> _guard<T>(
    CancellationToken? cancellation,
    Future<Result<T>> Function(CancelToken? cancelToken) request,
  ) async {
    final cancelToken = cancellation == null ? null : CancelToken();
    if (cancellation != null) {
      unawaited(cancellation.whenCancelled.then((_) => cancelToken?.cancel()));
    }
    try {
      return await request(cancelToken);
    } on DioException catch (exception) {
      return Err(mapDioException(exception));
    } on FormatException {
      return const Err(ParsingFailure());
    }
  }
}
