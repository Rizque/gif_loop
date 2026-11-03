import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:gif_loop/core/errors/failure_mapper.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/media/file_download.dart';
import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/data/library_records.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/domain/remix_draft.dart';
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
  }) : _favoritesDirectory = Directory('${documents.path}/$favoritesFolder'),
       _remixesDirectory = Directory('${documents.path}/$remixesFolder');

  static const String favoritesFolder = 'favorites';
  static const String remixesFolder = 'remixes';
  static const String favoritesKey = 'library_favorites';
  static const String remixesKey = 'library_remixes';

  final SharedPreferencesAsync _preferences;
  final Directory _favoritesDirectory;
  final Directory _remixesDirectory;
  final FileDownload _download;
  final DateTime Function() _clock;
  Future<void> _lastWrite = Future.value();

  @override
  Future<List<FavoriteGif>> favorites() async =>
      (await _readFavorites()).map(_resolveFavorite).toList();

  @override
  Future<FavoriteGif?> favorite(String gifId) async {
    for (final record in await _readFavorites()) {
      if (record.gif.id == gifId) return _resolveFavorite(record);
    }
    return null;
  }

  @override
  Future<Result<FavoriteGif>> addFavorite(Gif gif) => _serialized(() async {
    final baseName = _safeFileName(gif.id);
    final record = FavoriteRecord(
      gif: gif,
      previewFileName: '${baseName}_preview${_extensionOf(gif.preview.url)}',
      fullFileName: '${baseName}_full${_extensionOf(gif.full.url)}',
      addedAt: _clock(),
    );
    final favorite = _resolveFavorite(record);
    final files = [favorite.previewFile, favorite.fullFile];
    try {
      await _favoritesDirectory.create(recursive: true);
      await _download(gif.preview.url, favorite.previewFile);
      await _download(gif.full.url, favorite.fullFile);
    } on Exception catch (error) {
      await _deleteFiles(files);
      return Err(mapMediaError(error));
    }
    final records = await _readFavorites();
    await _writeRecords(favoritesKey, [
      record.toJson(),
      for (final existing in records)
        if (existing.gif.id != gif.id) existing.toJson(),
    ]);
    return Success(favorite);
  });

  @override
  Future<void> removeFavorite(String gifId) => _serialized(() async {
    final records = await _readFavorites();
    await _writeRecords(favoritesKey, [
      for (final record in records)
        if (record.gif.id != gifId) record.toJson(),
    ]);
    for (final record in records.where((record) => record.gif.id == gifId)) {
      final favorite = _resolveFavorite(record);
      await _deleteFiles([favorite.previewFile, favorite.fullFile]);
    }
  });

  @override
  Future<List<Remix>> remixes() async =>
      (await _readRemixes()).map(_resolveRemix).toList();

  @override
  Future<Result<Remix>> saveRemix(Uint8List bytes, RemixDraft draft) =>
      _serialized(() async {
        final createdAt = _clock();
        final id = createdAt.microsecondsSinceEpoch.toString();
        final record = RemixRecord(
          id: id,
          sourceGifId: draft.sourceGifId,
          sourceTitle: draft.sourceTitle,
          fileName: '$id.gif',
          width: draft.width,
          height: draft.height,
          frameCount: draft.frameCount,
          durationMs: draft.duration.inMilliseconds,
          sizeBytes: bytes.length,
          createdAt: createdAt,
        );
        final remix = _resolveRemix(record);
        try {
          await _remixesDirectory.create(recursive: true);
          await remix.file.writeAsBytes(bytes, flush: true);
          final records = await _readRemixes();
          await _writeRecords(remixesKey, [
            record.toJson(),
            for (final existing in records) existing.toJson(),
          ]);
        } on Exception catch (error) {
          await _deleteFiles([remix.file]);
          return Err(mapMediaError(error));
        }
        return Success(remix);
      });

  @override
  Future<void> deleteRemix(String remixId) => _serialized(() async {
    final records = await _readRemixes();
    await _writeRecords(remixesKey, [
      for (final record in records)
        if (record.id != remixId) record.toJson(),
    ]);
    for (final record in records.where((record) => record.id == remixId)) {
      await _deleteFiles([_resolveRemix(record).file]);
    }
  });

  FavoriteGif _resolveFavorite(FavoriteRecord record) => FavoriteGif(
    gif: record.gif,
    previewFile: File('${_favoritesDirectory.path}/${record.previewFileName}'),
    fullFile: File('${_favoritesDirectory.path}/${record.fullFileName}'),
    addedAt: record.addedAt,
  );

  Remix _resolveRemix(RemixRecord record) => Remix(
    id: record.id,
    sourceGifId: record.sourceGifId,
    sourceTitle: record.sourceTitle,
    file: File('${_remixesDirectory.path}/${record.fileName}'),
    width: record.width,
    height: record.height,
    frameCount: record.frameCount,
    duration: Duration(milliseconds: record.durationMs),
    sizeBytes: record.sizeBytes,
    createdAt: record.createdAt,
  );

  Future<List<FavoriteRecord>> _readFavorites() async => [
    for (final json in await _readRecords(favoritesKey))
      ?FavoriteRecord.fromJson(json),
  ];

  Future<List<RemixRecord>> _readRemixes() async => [
    for (final json in await _readRecords(remixesKey))
      ?RemixRecord.fromJson(json),
  ];

  Future<List<Map<String, dynamic>>> _readRecords(String key) async {
    final stored = await _preferences.getString(key);
    if (stored == null) return const [];
    try {
      final decoded = jsonDecode(stored);
      return decoded is List ? decoded.map(readMap).nonNulls.toList() : [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> _writeRecords(String key, List<Map<String, Object?>> records) =>
      _preferences.setString(key, jsonEncode(records));

  // Writes are serialized so two quick changes cannot overwrite each other's
  // metadata.
  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _lastWrite.then((_) => action());
    _lastWrite = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static Future<void> _deleteFiles(List<File> files) async {
    for (final file in files) {
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
