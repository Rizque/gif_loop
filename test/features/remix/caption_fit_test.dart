import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/remix/export/caption_fit.dart';

void main() {
  group('fitCaptionFontSize', () {
    test('keeps the max size when the caption fits', () {
      expect(
        fitCaptionFontSize(maxSize: 40, minSize: 12, fits: (_) => true),
        40,
      );
    });

    test('shrinks to the largest size that fits', () {
      expect(
        fitCaptionFontSize(
          maxSize: 40,
          minSize: 12,
          fits: (size) => size <= 27,
        ),
        27,
      );
    });

    test('falls back to the min size when nothing fits', () {
      expect(
        fitCaptionFontSize(maxSize: 40, minSize: 12, fits: (_) => false),
        12,
      );
    });
  });
}
