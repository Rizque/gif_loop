import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/library/data/local_library_repository.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/domain/remix_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/preferences.dart';

void main() {
  late Directory documents;
  late SharedPreferencesAsync preferences;

  const draft = RemixDraft(
    sourceGifId: 'abc',
    sourceTitle: 'Dancing cat',
    width: 480,
    height: 270,
    frameCount: 24,
    duration: Duration(milliseconds: 2400),
  );
  final bytes = Uint8List.fromList(List.filled(64, 7));

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('gif_loop_remixes');
    preferences = inMemoryPreferences();
  });

  tearDown(() => documents.delete(recursive: true));

  LocalLibraryRepository buildRepository({DateTime? now}) =>
      LocalLibraryRepository(
        preferences: preferences,
        documents: documents,
        download: (url, destination) async {},
        clock: () => now ?? DateTime(2026, 11, 3, 12),
      );

  Directory remixesFolder() =>
      Directory('${documents.path}/${LocalLibraryRepository.remixesFolder}');

  group('LocalLibraryRepository remixes', () {
    test('saves the GIF into remixes/ with its metadata', () async {
      final result = await buildRepository().saveRemix(bytes, draft);

      final remix = (result as Success<Remix>).value;
      expect(remix.file.readAsBytesSync(), bytes);
      expect(remix.file.parent.path, remixesFolder().path);
      expect(remix.file.path, endsWith('${remix.id}.gif'));
      expect(remix.sizeBytes, bytes.length);
      expect(remix.frameCount, 24);
      expect(remix.duration, const Duration(milliseconds: 2400));
      expect(remix.sourceTitle, 'Dancing cat');
    });

    test('lists remixes newest first and persists them', () async {
      await buildRepository(now: DateTime(2026)).saveRemix(bytes, draft);
      await buildRepository(now: DateTime(2027)).saveRemix(bytes, draft);

      final remixes = await buildRepository().remixes();

      expect([for (final remix in remixes) remix.createdAt.year], [2027, 2026]);
    });

    test('stores only file names, never absolute paths', () async {
      await buildRepository().saveRemix(bytes, draft);

      final stored = await preferences.getString(
        LocalLibraryRepository.remixesKey,
      );

      expect(stored, isNot(contains(documents.path)));
      expect(stored, isNot(contains(LocalLibraryRepository.remixesFolder)));
    });

    test('deleting a remix removes the file and the metadata', () async {
      final repository = buildRepository();
      final remix =
          ((await repository.saveRemix(bytes, draft)) as Success<Remix>).value;

      await repository.deleteRemix(remix.id);

      expect(remix.file.existsSync(), isFalse);
      expect(await repository.remixes(), isEmpty);
    });

    test('a failed write leaves no metadata and no orphan file', () async {
      File(remixesFolder().path).writeAsStringSync('not a folder');

      final result = await buildRepository().saveRemix(bytes, draft);

      expect((result as Err<Remix>).failure, const StorageFailure());
      expect(await buildRepository().remixes(), isEmpty);
    });
  });
}
