import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/media/image_bytes.dart';

Uint8List _bytes(String text) => Uint8List.fromList(text.codeUnits);

void main() {
  group('isSupportedImage', () {
    test('accepts both GIF versions', () {
      expect(isSupportedImage(_bytes('GIF89a....')), isTrue);
      expect(isSupportedImage(_bytes('GIF87a....')), isTrue);
    });

    test('accepts WebP', () {
      expect(isSupportedImage(_bytes('RIFF\x66\x15\x00\x00WEBPVP8 ')), isTrue);
    });

    test('rejects empty and too short input', () {
      expect(isSupportedImage(Uint8List(0)), isFalse);
      expect(isSupportedImage(_bytes('GIF')), isFalse);
      expect(isSupportedImage(_bytes('RIFF\x66\x15\x00\x00WEB')), isFalse);
    });

    test('rejects other content', () {
      expect(isSupportedImage(_bytes('<!DOCTYPE html>')), isFalse);
      expect(isSupportedImage(_bytes('{"meta":{"status":404}}')), isFalse);
      expect(isSupportedImage(_bytes('GIF90a....')), isFalse);
    });

    test('rejects a RIFF container that is not WebP', () {
      expect(isSupportedImage(_bytes('RIFF\x66\x15\x00\x00WAVEfmt ')), isFalse);
    });
  });
}
