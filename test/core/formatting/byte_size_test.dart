import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/formatting/byte_size.dart';

void main() {
  group('formatByteSize', () {
    test('formats bytes, kilobytes and megabytes', () {
      expect(formatByteSize(512), '512 B');
      expect(formatByteSize(2048), '2 KB');
      expect(formatByteSize(1734322), '1.7 MB');
    });
  });
}
