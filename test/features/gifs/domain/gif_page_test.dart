import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';

void main() {
  GifPage page({
    required int offset,
    required int count,
    int totalCount = 10000,
    int maxOffset = 4999,
  }) => GifPage(
    items: const [],
    offset: offset,
    count: count,
    totalCount: totalCount,
    maxOffset: maxOffset,
  );

  group('GifPage.hasMore', () {
    test('is true while more items exist', () {
      expect(page(offset: 0, count: 30).hasMore, isTrue);
    });

    test('is false when total_count is reached', () {
      expect(page(offset: 90, count: 30, totalCount: 120).hasMore, isFalse);
    });

    test('is false when the next offset exceeds the GIPHY max offset', () {
      expect(page(offset: 4980, count: 30).hasMore, isFalse);
      expect(page(offset: 4950, count: 30).hasMore, isTrue);
    });

    test('is false when the page is empty', () {
      expect(page(offset: 30, count: 0).hasMore, isFalse);
    });
  });
}
