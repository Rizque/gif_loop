import 'dart:math';

const int bytesPerPixel = 4;

// Every decoded frame is kept in memory, so large GIFs are decoded at a
// smaller width (aspect ratio preserved) to stay under the budget.
int? targetWidthWithinBudget({
  required int width,
  required int height,
  required int frameCount,
  required int budgetBytes,
}) {
  final requiredBytes = frameCount * width * height * bytesPerPixel;
  if (requiredBytes <= budgetBytes) return null;
  final scale = sqrt(budgetBytes / requiredBytes);
  return max(1, (width * scale).floor());
}
