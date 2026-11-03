import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/library/data/local_library_repository.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/preferences.dart';

void main() {
  late Directory documents;
  late SharedPreferencesAsync preferences;
  late List<String> downloadedUrls;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('gif_loop_library');
    preferences = inMemoryPreferences();
    downloadedUrls = [];
  });

  tearDown(() => documents.delete(recursive: true));

  Future<void> fakeDownload(String url, File destination) async {
    downloadedUrls.add(url);
    await destination.writeAsBytes(utf8.encode(url));
  }

  LocalLibraryRepository buildRepository({
    Future<void> Function(String url, File destination)? download,
  }) => LocalLibraryRepository(
    preferences: preferences,
    documents: documents,
    download: download ?? fakeDownload,
    clock: () => DateTime(2026, 11, 3),
  );

  FavoriteGif favoriteOf(Result<FavoriteGif> result) =>
      (result as Success<FavoriteGif>).value;

  group('LocalLibraryRepository favorites', () {
    test('downloads both renditions into favorites/', () async {
      final repository = buildRepository();
      final gif = makeGif('abc');

      final favorite = favoriteOf(await repository.addFavorite(gif));

      expect(downloadedUrls, [gif.preview.url, gif.full.url]);
      expect(favorite.previewFile.existsSync(), isTrue);
      expect(favorite.fullFile.existsSync(), isTrue);
      expect(
        favorite.fullFile.parent.path,
        endsWith(LocalLibraryRepository.favoritesFolder),
      );
      expect(favorite.previewFile.path, endsWith('abc_preview.webp'));
      expect(favorite.fullFile.path, endsWith('abc_full.gif'));
    });

    test('lists favorites newest first without duplicates', () async {
      final repository = buildRepository();
      await repository.addFavorite(makeGif('a'));
      await repository.addFavorite(makeGif('b'));
      await repository.addFavorite(makeGif('a'));

      final ids = [
        for (final favorite in await repository.favorites()) favorite.gif.id,
      ];
      expect(ids, ['a', 'b']);
    });

    test('persists across instances', () async {
      await buildRepository().addFavorite(makeGif('abc', title: 'Kitty'));

      final reopened = buildRepository();
      final favorite = await reopened.favorite('abc');

      expect(favorite?.gif, makeGif('abc', title: 'Kitty'));
      expect(favorite?.addedAt, DateTime(2026, 11, 3));
      expect(favorite?.fullFile.existsSync(), isTrue);
    });

    test('stores only file names, never absolute paths', () async {
      await buildRepository().addFavorite(makeGif('abc'));

      final stored = await preferences.getString(
        LocalLibraryRepository.favoritesKey,
      );

      expect(stored, isNot(contains(documents.path)));
      expect(stored, isNot(contains(LocalLibraryRepository.favoritesFolder)));
      expect(stored, contains('"previewFileName":"abc_preview.webp"'));
    });

    test('removing a favorite deletes its metadata and files', () async {
      final repository = buildRepository();
      final favorite = favoriteOf(await repository.addFavorite(makeGif('abc')));

      await repository.removeFavorite('abc');

      expect(await repository.favorites(), isEmpty);
      expect(favorite.previewFile.existsSync(), isFalse);
      expect(favorite.fullFile.existsSync(), isFalse);
    });

    test('a failed download leaves no metadata and no files', () async {
      final repository = buildRepository(
        download: (url, destination) async {
          await destination.writeAsString('partial');
          if (url.contains('giphy.gif')) {
            throw const SocketException('offline');
          }
        },
      );

      final result = await repository.addFavorite(makeGif('abc'));

      expect((result as Err<FavoriteGif>).failure, const NoConnectionFailure());
      expect(await repository.favorites(), isEmpty);
      final favoritesFolder = Directory(
        '${documents.path}/${LocalLibraryRepository.favoritesFolder}',
      );
      expect(favoritesFolder.listSync(), isEmpty);
    });

    test('ignores corrupted metadata', () async {
      await preferences.setString(LocalLibraryRepository.favoritesKey, '{oops');

      expect(await buildRepository().favorites(), isEmpty);
    });
  });
}
