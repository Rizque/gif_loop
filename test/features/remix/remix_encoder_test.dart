import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/remix/export/remix_encoder.dart';
import 'package:image/image.dart' as img;

import '../../helpers/test_gif.dart';

void main() {
  const plan = [
    RemixFrame(2, Duration(milliseconds: 200)),
    RemixFrame(1, Duration(milliseconds: 50)),
    RemixFrame(2, Duration(milliseconds: 30)),
  ];

  Uint8List redSquareOverlay(int width, int height) {
    final overlay = Uint8List(width * height * 4);
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        final offset = (y * width + x) * 4;
        overlay
          ..[offset] = 255
          ..[offset + 3] = 255;
      }
    }
    return overlay;
  }

  group('encodeRemix', () {
    test('writes the planned frames, delays and size', () {
      final output = encodeRemix(
        RemixEncodeJob(
          sourceBytes: buildTestGif(),
          frames: plan,
          width: 10,
          height: 5,
        ),
      );

      final decoded = img.GifDecoder().decode(output)!;
      expect(decoded.frames, hasLength(3));
      expect(decoded.width, 10);
      expect(decoded.height, 5);
      expect(
        [for (final frame in decoded.frames) frame.frameDuration],
        [200, 50, 30],
      );
      expect(decoded.loopCount, 0);
      final firstPixel = decoded.frames.first.getPixel(5, 3);
      expect(firstPixel.r, greaterThan(200));
      expect(firstPixel.g, greaterThan(200));
      expect(firstPixel.b, lessThan(60));
    });

    test('composites the caption overlay on every frame', () {
      final output = encodeRemix(
        RemixEncodeJob(
          sourceBytes: buildTestGif(),
          frames: plan,
          width: 10,
          height: 5,
          overlayRgba: redSquareOverlay(10, 5),
        ),
      );

      final decoded = img.GifDecoder().decode(output)!;
      for (final frame in decoded.frames) {
        final overlaid = frame.getPixel(0, 0);
        expect(overlaid.r, greaterThan(200));
        expect(overlaid.g, lessThan(60));
        expect(overlaid.b, lessThan(60));
      }
    });

    test('reports progress per frame', () {
      final progress = <double>[];

      encodeRemix(
        RemixEncodeJob(
          sourceBytes: buildTestGif(),
          frames: plan,
          width: 10,
          height: 5,
        ),
        onProgress: progress.add,
      );

      expect(progress, [1 / 3, 2 / 3, 1]);
    });

    test('throws for bytes that are not a GIF', () {
      expect(
        () => encodeRemix(
          RemixEncodeJob(
            sourceBytes: Uint8List.fromList([1, 2, 3]),
            frames: plan,
            width: 10,
            height: 5,
          ),
        ),
        throwsFormatException,
      );
    });
  });
}
