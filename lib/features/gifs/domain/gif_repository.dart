import 'package:gif_loop/core/config/giphy_config.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';

abstract interface class GifRepository {
  Future<Result<GifPage>> trending({
    required int offset,
    CancellationToken? cancellation,
  });

  Future<Result<GifPage>> search(
    String query, {
    required int offset,
    int limit = GiphyConfig.pageSize,
    ContentRating rating = ContentRating.pg,
    CancellationToken? cancellation,
  });

  Future<Result<Gif>> gifById(String id);
}
