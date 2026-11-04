import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';

import '../../helpers/fixture.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_gif.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late GifFrameLoader loader;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('gif_frame_loader');
    loader = GifFrameLoader(MockCacheManager());
  });

  tearDown(() => directory.deleteSync(recursive: true));

  Future<Result<List<GifFrame>>> decode(
    Uint8List bytes, {
    CancellationToken? cancellation,
  }) {
    final file = File('${directory.path}/source')..writeAsBytesSync(bytes);
    return loader.load(
      file: file,
      cancellation: cancellation ?? CancellationToken(),
      onProgress: (_) {},
    );
  }

  group('single-frame GIF', () {
    test('decodes to exactly one frame', () async {
      final result = await decode(singleFrameGif());

      final frames = (result as Success<List<GifFrame>>).value;
      expect(frames, hasLength(1));
      expect(frames.single.image.width, 20);
      expect(frames.single.image.height, 10);
      expect(frames.single.duration, Duration.zero);
      frames.single.image.dispose();
    });

    test('decodes real pixels', () async {
      final result = await decode(singleFrameGif());

      final image = (result as Success<List<GifFrame>>).value.single.image;
      final pixels = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      expect(pixels!.buffer.asUint8List().take(4), [30, 120, 220, 255]);
      image.dispose();
    });

    test('reports full progress', () async {
      final progress = <double>[];
      final file = File('${directory.path}/still.gif')
        ..writeAsBytesSync(singleFrameGif());

      final result = await loader.load(
        file: file,
        cancellation: CancellationToken(),
        onProgress: progress.add,
      );

      expect(progress, [1]);
      (result as Success<List<GifFrame>>).value.single.image.dispose();
    });
  });

  test('decodes every frame of an animated GIF', () async {
    final result = await decode(buildTestGif());

    final frames = (result as Success<List<GifFrame>>).value;
    expect(frames, hasLength(testGifColors.length));
    expect(frames.first.duration, const Duration(milliseconds: 100));
    for (final frame in frames) {
      frame.image.dispose();
    }
  });

  group('invalid bytes never reach the engine', () {
    final invalid = <String, Uint8List>{
      'an empty file': Uint8List(0),
      'an HTML error page': Uint8List.fromList(
        '<!DOCTYPE html><html></html>'.codeUnits,
      ),
      'a truncated header': Uint8List.fromList('GIF'.codeUnits),
    };

    for (final MapEntry(key: name, value: bytes) in invalid.entries) {
      test('rejects $name', () async {
        final result = await decode(bytes);

        expect(
          (result as Err<List<GifFrame>>).failure,
          const DecodingFailure(),
        );
      });
    }
  });

  test('a GIF header without a body becomes a decoding failure', () async {
    final result = await decode(Uint8List.fromList('GIF89a'.codeUnits));

    expect((result as Err<List<GifFrame>>).failure, const DecodingFailure());
  });

  test('a cancelled load decodes nothing', () async {
    final result = await decode(
      singleFrameGif(),
      cancellation: CancellationToken()..cancel(),
    );

    expect(result, isA<Err<List<GifFrame>>>());
  });
}
