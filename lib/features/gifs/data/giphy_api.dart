import 'package:dio/dio.dart';
import 'package:gif_loop/core/config/giphy_config.dart';
import 'package:gif_loop/features/gifs/data/dto/gif_dto.dart';
import 'package:gif_loop/features/gifs/data/dto/gif_list_response_dto.dart';
import 'package:gif_loop/features/gifs/data/dto/json_read.dart';

class GiphyApi {
  const new(this._dio);

  final Dio _dio;

  Future<GifListResponseDto> trending({
    required int offset,
    required int limit,
    required String rating,
    CancelToken? cancelToken,
  }) async {
    final json = await _get('gifs/trending', {
      'offset': offset,
      'limit': limit,
      'rating': rating,
    }, cancelToken);
    return GifListResponseDto.fromJson(json);
  }

  Future<GifListResponseDto> search({
    required String query,
    required int offset,
    required int limit,
    required String rating,
    CancelToken? cancelToken,
  }) async {
    final json = await _get('gifs/search', {
      'q': query,
      'offset': offset,
      'limit': limit,
      'rating': rating,
      'lang': GiphyConfig.language,
    }, cancelToken);
    return GifListResponseDto.fromJson(json);
  }

  Future<GifDto?> gifById(String id) async {
    final json = await _get('gifs/${Uri.encodeComponent(id)}', const {});
    final data = readMap(json['data']);
    return data == null ? null : GifDto.fromJson(data);
  }

  Future<List<String>> searchTags(
    String query, {
    required int limit,
    CancelToken? cancelToken,
  }) async {
    final json = await _get('gifs/search/tags', {
      'q': query,
      'limit': limit,
    }, cancelToken);
    return _dataList(json)
        .map(readMap)
        .nonNulls
        .map((tag) => readString(tag['name']))
        .nonNulls
        .toList();
  }

  Future<List<String>> trendingSearches() async {
    final json = await _get('trending/searches', const {});
    return _dataList(json).map(readString).nonNulls.toList();
  }

  static List<Object?> _dataList(Map<String, dynamic> json) =>
      switch (json['data']) {
        final List<Object?> data => data,
        _ => throw const FormatException('GIPHY response has no data array'),
      };

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, Object> queryParameters, [
    CancelToken? cancelToken,
  ]) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) throw const FormatException('Empty GIPHY response');
    return data;
  }
}
