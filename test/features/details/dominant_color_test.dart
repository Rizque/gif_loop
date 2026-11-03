import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/details/color/dominant_color.dart';

typedef _Pixel = (int r, int g, int b, int a);

Uint8List _image(Map<_Pixel, int> pixelCounts) => Uint8List.fromList([
  for (final MapEntry(key: (r, g, b, a), value: count) in pixelCounts.entries)
    for (var i = 0; i < count; i++) ...[r, g, b, a],
]);

void main() {
  group('dominantArgb', () {
    test('returns the color of a solid image', () {
      expect(dominantArgb(_image({(200, 40, 120, 255): 64})), 0xFFC82878);
    });

    test('ignores near-black and near-white pixels', () {
      final pixels = _image({
        (0, 0, 0, 255): 500,
        (255, 255, 255, 255): 500,
        (10, 12, 8, 255): 200,
        (240, 238, 250, 255): 200,
        (30, 120, 220, 255): 20,
      });

      expect(dominantArgb(pixels), 0xFF1E78DC);
    });

    test('ignores transparent pixels', () {
      final pixels = _image({(220, 30, 30, 0): 500, (30, 160, 60, 255): 10});

      expect(dominantArgb(pixels), 0xFF1EA03C);
    });

    test('picks the most frequent bucket in a mixed image', () {
      final pixels = _image({
        (200, 40, 40, 255): 30,
        (40, 200, 40, 255): 50,
        (40, 40, 200, 255): 20,
      });

      expect(dominantArgb(pixels), 0xFF28C828);
    });

    test('averages similar shades within the winning bucket', () {
      final pixels = _image({(100, 50, 200, 255): 1, (110, 60, 206, 255): 1});

      expect(dominantArgb(pixels), 0xFF6937CB);
    });

    test('returns null when every pixel is ignored', () {
      expect(dominantArgb(_image({(0, 0, 0, 255): 10})), isNull);
      expect(dominantArgb(Uint8List(0)), isNull);
    });
  });
}
