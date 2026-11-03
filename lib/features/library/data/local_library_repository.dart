import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gif_loop/core/errors/failure_mapper.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/media/file_download.dart';
import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/data/gif_json.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Metadata lives in shared_preferences and files in the documents directory.
// Only file names are stored: the iOS app container path changes between
// installs and updates, so paths are resolved at runtime.
class LocalLibraryRepository implements LibraryRepository {
  new({
    required this._preferences,
    required Directory documents,
    required this._download,
    this._clock = DateTime.now,
  }) : _favoritesDirectory = Directory('${documents.path}/$favoritesFolder');

  static const String favoritesFolder = 'favorites';
  static const String favoritesKey = 'library_favorites';

  final SharedPreferencesAsync _preferences;
  final Directory _favoritesDirectory;
  final FileDownload _download;
  final DateTime Function() _clock;
  Future<void> _lastWrite = Future.value();

  @override
  Future<List<FavoriteGif>> favorites() async =>
      (await _readFavorites()).map(_resolve).toList();

  @override
  Future<FavoriteGif?> favorite(String gifId) async {
    for (final record in await _readFavorites()) {
      if (record.gif.id == gifId) return _resolve(record);
    }
    return null;
  }

  @override
  Future<Result<FavoriteGif>> addFavorite(Gif gif) => _serialized(() async {
    final baseName = _safeFileName(gif.id);
    final record = _FavoriteRecord(
      gif: gif,
      previewFileName: '${baseName}_preview${_extensionOf(gif.preview.url)}',
      fullFileName: '${baseName}_full${_extensionOf(gif.full.url)}',
      addedAt: _clock(),
    );
    final favorite = _resolve(record);
    try {
      await _favoritesDirectory.create(recursive: true);
      await _download(gif.preview.url, favorite.previewFile);
      await _download(gif.full.url, favorite.fullFile);
    } on Exception catch (error) {
      await _deleteFiles(favorite);
      return Err(mapMediaError(error));
    }
    final records = await _readFavorites();
    await _writeFavorites([
      record,
      ...records.where((existing) => existing.gif.id != gif.id),
    ]);
    return Success(favorite);
  });

  @override
  Future<void> removeFavorite(String gifId) => _serialized(() async {
    final records = await _readFavorites();
    await _writeFavorites(
      records.where((record) => record.gif.id != gifId).toList(),
    );
    for (final record in records.where((record) => record.gif.id == gifId)) {
      await _deleteFiles(_resolve(record));
    }
  });

  FavoriteGif _resolve(_FavoriteRecord record) => FavoriteGif(
    gif: record.gif,
    previewFile: _favoriteFile(record.previewFileName),
    fullFile: _favoriteFile(record.fullFileName),
    addedAt: record.addedAt,
  );

  File _favoriteFile(String fileName) =>
      File('${_favoritesDirectory.path}/$fileName');

  Future<List<_FavoriteRecord>> _readFavorites() async {
    final stored = await _preferences.getString(favoritesKey);
    if (stored == null) return const [];
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List) return const [];
      return decoded
          .map(readMap)
          .nonNulls
          .map(_FavoriteRecord.fromJson)
          .nonNulls
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeFavorites(List<_FavoriteRecord> records) =>
      _preferences.setString(
        favoritesKey,
        jsonEncode([for (final record in records) record.toJson()]),
      );

  // Writes are serialized so two quick favorite toggles cannot overwrite
  // each other's metadata.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _lastWrite.then((_) => action());
    _lastWrite = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static Future<void> _deleteFiles(FavoriteGif favorite) async {
    for (final file in [favorite.previewFile, favorite.fullFile]) {
      try {
        if (file.existsSync()) await file.delete();
      } on FileSystemException {
        continue;
      }
    }
  }

  static String _safeFileName(String id) =>
      id.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');

  static String _extensionOf(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    return dot < 0 || dot < path.lastIndexOf('/')
        ? '.gif'
        : path.substring(dot);
  }
}

class _FavoriteRecord {
  const new({
    required this.gif,
    required this.previewFileName,
    required this.fullFileName,
    required this.addedAt,
  });

  static _FavoriteRecord? fromJson(Map<String, dynamic> json) {
    final gif = switch (readMap(json['gif'])) {
      final gifJson? => gifFromJson(gifJson),
      null => null,
    };
    final previewFileName = readString(json['previewFileName']);
    final fullFileName = readString(json['fullFileName']);
    final addedAt = DateTime.tryParse(readString(json['addedAt']) ?? '');
    if (gif == null ||
        previewFileName == null ||
        fullFileName == null ||
        addedAt == null) {
      return null;
    }
    return _FavoriteRecord(
      gif: gif,
      previewFileName: previewFileName,
      fullFileName: fullFileName,
      addedAt: addedAt,
    );
  }

  final Gif gif;
  final String previewFileName;
  final String fullFileName;
  final DateTime addedAt;

  Map<String, Object?> toJson() => {
    'gif': gifToJson(gif),
    'previewFileName': previewFileName,
    'fullFileName': fullFileName,
    'addedAt': addedAt.toIso8601String(),
  };
}
