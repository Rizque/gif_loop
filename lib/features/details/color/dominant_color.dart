import 'dart:typed_data';

const int _opaqueAlpha = 0xFF000000;
const int _minAlpha = 128;
const int _nearBlackMax = 32;
const int _nearWhiteMin = 224;
const int _bucketShift = 4;
const int _bucketsPerChannel = 1 << (8 - _bucketShift);

// Returns the average ARGB color of the most common bucket of a raw RGBA
// buffer, ignoring transparent, near-black and near-white pixels.
int? dominantArgb(Uint8List rgba) {
  const bucketCount =
      _bucketsPerChannel * _bucketsPerChannel * _bucketsPerChannel;
  final counts = Int32List(bucketCount);
  final redSums = Int32List(bucketCount);
  final greenSums = Int32List(bucketCount);
  final blueSums = Int32List(bucketCount);

  for (var i = 0; i + 3 < rgba.length; i += 4) {
    final red = rgba[i];
    final green = rgba[i + 1];
    final blue = rgba[i + 2];
    if (rgba[i + 3] < _minAlpha) continue;
    final brightest = _max3(red, green, blue);
    final darkest = _min3(red, green, blue);
    if (brightest < _nearBlackMax || darkest > _nearWhiteMin) continue;

    final bucket =
        (red >> _bucketShift) * _bucketsPerChannel * _bucketsPerChannel +
        (green >> _bucketShift) * _bucketsPerChannel +
        (blue >> _bucketShift);
    counts[bucket]++;
    redSums[bucket] += red;
    greenSums[bucket] += green;
    blueSums[bucket] += blue;
  }

  var best = -1;
  for (var bucket = 0; bucket < bucketCount; bucket++) {
    if (counts[bucket] > 0 && (best < 0 || counts[bucket] > counts[best])) {
      best = bucket;
    }
  }
  if (best < 0) return null;

  final count = counts[best];
  return _opaqueAlpha |
      (redSums[best] ~/ count) << 16 |
      (greenSums[best] ~/ count) << 8 |
      blueSums[best] ~/ count;
}

int _max3(int a, int b, int c) => a > b ? (a > c ? a : c) : (b > c ? b : c);

int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);
