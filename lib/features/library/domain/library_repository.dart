import 'dart:typed_data';

import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/domain/remix_draft.dart';

// The seam for a future cloud-backed library: the UI only talks to this.
abstract interface class LibraryRepository {
  Future<List<FavoriteGif>> favorites();

  Future<FavoriteGif?> favorite(String gifId);

  Future<Result<FavoriteGif>> addFavorite(Gif gif);

  Future<void> removeFavorite(String gifId);

  Future<List<Remix>> remixes();

  Future<Result<Remix>> saveRemix(Uint8List bytes, RemixDraft draft);

  Future<void> deleteRemix(String remixId);
}
