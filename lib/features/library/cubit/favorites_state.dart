import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';

class FavoritesState extends Equatable {
  const new({
    this.favorites = const [],
    this.savingIds = const {},
    this.isLoaded = false,
  });

  final List<FavoriteGif> favorites;
  final Set<String> savingIds;
  final bool isLoaded;

  bool isFavorite(String gifId) =>
      savingIds.contains(gifId) || favoriteOf(gifId) != null;

  FavoriteGif? favoriteOf(String gifId) {
    for (final favorite in favorites) {
      if (favorite.gif.id == gifId) return favorite;
    }
    return null;
  }

  @override
  List<Object?> get props => [favorites, savingIds, isLoaded];
}
