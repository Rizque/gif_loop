import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/favorites_state.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockLibraryRepository repository;

  final gif = makeGif('abc');
  final favorite = FavoriteGif(
    gif: gif,
    previewFile: File('favorites/abc_preview.webp'),
    fullFile: File('favorites/abc_full.gif'),
    addedAt: DateTime(2026),
  );

  setUpAll(() => registerFallbackValue(makeGif('fallback')));

  setUp(() {
    repository = MockLibraryRepository();
    when(() => repository.removeFavorite(any())).thenAnswer((_) async {});
  });

  group('FavoritesCubit', () {
    blocTest<FavoritesCubit, FavoritesState>(
      'loads saved favorites',
      setUp: () =>
          when(repository.favorites).thenAnswer((_) async => [favorite]),
      build: () => FavoritesCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        FavoritesState(favorites: [favorite], isLoaded: true),
      ],
    );

    test('shows the heart as favorited while saving', () async {
      final saving = Completer<Result<FavoriteGif>>();
      when(() => repository.addFavorite(gif)).thenAnswer((_) => saving.future);
      final cubit = FavoritesCubit(repository);

      final toggling = cubit.toggle(gif);
      expect(cubit.state.isFavorite(gif.id), isTrue);
      expect(cubit.state.favoriteOf(gif.id), isNull);

      saving.complete(Success(favorite));
      expect(await toggling, isNull);
      expect(cubit.state.favoriteOf(gif.id), favorite);
      expect(cubit.state.savingIds, isEmpty);
    });

    blocTest<FavoritesCubit, FavoritesState>(
      'rolls back and reports the failure when saving fails',
      setUp: () =>
          when(() => repository.addFavorite(gif))
              .thenAnswer((_) async => const Err(StorageFailure())),
      build: () => FavoritesCubit(repository),
      act: (cubit) async =>
          expect(await cubit.toggle(gif), const StorageFailure()),
      expect: () => [
        FavoritesState(savingIds: {gif.id}),
        const FavoritesState(),
      ],
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'removes an existing favorite',
      seed: () => FavoritesState(favorites: [favorite], isLoaded: true),
      build: () => FavoritesCubit(repository),
      act: (cubit) => cubit.toggle(gif),
      expect: () => [const FavoritesState(isLoaded: true)],
      verify: (_) => verify(() => repository.removeFavorite(gif.id)).called(1),
    );

    blocTest<FavoritesCubit, FavoritesState>(
      'ignores taps while the same GIF is being saved',
      seed: () => FavoritesState(savingIds: {gif.id}),
      build: () => FavoritesCubit(repository),
      act: (cubit) => cubit.toggle(gif),
      expect: () => <FavoritesState>[],
      verify: (_) => verifyNever(() => repository.addFavorite(any())),
    );
  });
}
