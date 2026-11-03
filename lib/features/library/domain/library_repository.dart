import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';

// The seam for a future cloud-backed library: the UI only talks to this.
abstract interface class LibraryRepository {
  Future<List<FavoriteGif>> favorites();

  Future<FavoriteGif?> favorite(String gifId);

  Future<Result<FavoriteGif>> addFavorite(Gif gif);

  Future<void> removeFavorite(String gifId);
}
