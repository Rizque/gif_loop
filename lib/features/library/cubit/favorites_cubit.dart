import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_state.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  new(this._repository) : super(const FavoritesState());

  final LibraryRepository _repository;

  Future<void> load() async {
    final favorites = await _repository.favorites();
    if (!isClosed) {
      emit(FavoritesState(favorites: favorites, isLoaded: true));
    }
  }

  // Optimistic: the heart fills immediately and rolls back if saving fails.
  Future<Failure?> toggle(Gif gif) async {
    if (state.savingIds.contains(gif.id)) return null;
    if (state.favoriteOf(gif.id) != null) {
      emit(_copy(favorites: _without(gif.id)));
      await _repository.removeFavorite(gif.id);
      return null;
    }
    emit(_copy(savingIds: {...state.savingIds, gif.id}));
    final result = await _repository.addFavorite(gif);
    if (isClosed) return null;
    final savingIds = {...state.savingIds}..remove(gif.id);
    switch (result) {
      case Success(value: final favorite):
        emit(
          _copy(
            favorites: [favorite, ..._without(gif.id)],
            savingIds: savingIds,
          ),
        );
        return null;
      case Err(:final failure):
        emit(_copy(savingIds: savingIds));
        return failure;
    }
  }

  List<FavoriteGif> _without(String gifId) =>
      state.favorites.where((favorite) => favorite.gif.id != gifId).toList();

  FavoritesState _copy({
    List<FavoriteGif>? favorites,
    Set<String>? savingIds,
  }) => FavoritesState(
    favorites: favorites ?? state.favorites,
    savingIds: savingIds ?? state.savingIds,
    isLoaded: state.isLoaded,
  );
}
