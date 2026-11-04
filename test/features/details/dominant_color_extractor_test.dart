import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';

import '../../helpers/fixture.dart';
import '../../helpers/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  final extractor = DominantColorExtractor(MockCacheManager());

  setUp(
    () => directory = Directory.systemTemp.createTempSync('dominant_color'),
  );

  tearDown(() => directory.deleteSync(recursive: true));

  Future<ui.Color?> extract(Uint8List bytes) {
    final file = File('${directory.path}/preview')..writeAsBytesSync(bytes);
    return extractor.extract('https://unused', localFile: file);
  }

  test('extracts the color of a single-frame GIF', () async {
    expect(await extract(singleFrameGif()), const ui.Color(0xFF1E78DC));
  });

  test('returns null for an empty file', () async {
    expect(await extract(Uint8List(0)), isNull);
  });

  test('returns null for a non-image response', () async {
    final html = Uint8List.fromList('<!DOCTYPE html>'.codeUnits);

    expect(await extract(html), isNull);
  });
}
