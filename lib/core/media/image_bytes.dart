import 'dart:typed_data';

const List<int> _gif87a = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61];
const List<int> _gif89a = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61];
const List<int> _riff = [0x52, 0x49, 0x46, 0x46];
const List<int> _webp = [0x57, 0x45, 0x42, 0x50];
const int _webpMarkerOffset = 8;

// GIPHY renditions and saved remixes are always GIF or WebP. Anything else
// (an empty file, a cached error page) must not reach the native decoder.
bool isSupportedImage(Uint8List bytes) =>
    _hasBytesAt(bytes, _gif89a) ||
    _hasBytesAt(bytes, _gif87a) ||
    (_hasBytesAt(bytes, _riff) &&
        _hasBytesAt(bytes, _webp, offset: _webpMarkerOffset));

bool _hasBytesAt(Uint8List bytes, List<int> expected, {int offset = 0}) {
  if (bytes.length < offset + expected.length) return false;
  for (var i = 0; i < expected.length; i++) {
    if (bytes[offset + i] != expected[i]) return false;
  }
  return true;
}
