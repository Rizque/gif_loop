import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/studio/decoder/memory_budget.dart';

void main() {
  const megabyte = 1024 * 1024;

  group('targetWidthWithinBudget', () {
    test('keeps the original size when the GIF fits', () {
      expect(
        targetWidthWithinBudget(
          width: 480,
          height: 270,
          frameCount: 60,
          budgetBytes: 120 * megabyte,
        ),
        isNull,
      );
    });

    test('scales down so all frames fit in the budget', () {
      const width = 1920;
      const height = 1080;
      const frames = 100;
      const budget = 120 * megabyte;

      final targetWidth = targetWidthWithinBudget(
        width: width,
        height: height,
        frameCount: frames,
        budgetBytes: budget,
      )!;
      final targetHeight = targetWidth * height / width;

      expect(targetWidth, lessThan(width));
      expect(
        frames * targetWidth * targetHeight * bytesPerPixel,
        lessThanOrEqualTo(budget),
      );
      expect(
        frames * targetWidth * targetHeight * bytesPerPixel,
        greaterThan(budget * 0.95),
      );
    });

    test('never returns a width below one pixel', () {
      expect(
        targetWidthWithinBudget(
          width: 100,
          height: 100,
          frameCount: 1000000,
          budgetBytes: 1,
        ),
        1,
      );
    });
  });
}
