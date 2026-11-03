import 'dart:typed_data';

import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:image/image.dart' as img;

class RemixEncodeJob {
  const new({
    required this.sourceBytes,
    required this.frames,
    required this.width,
    required this.height,
    this.overlayRgba,
  });

  final Uint8List sourceBytes;
  final List<RemixFrame> frames;
  final int width;
  final int height;
  final Uint8List? overlayRgba;
}

// Runs in a background isolate. Pure Dart so it can be tested directly.
Uint8List encodeRemix(
  RemixEncodeJob job, {
  void Function(double progress)? onProgress,
}) {
  final animation = img.GifDecoder().decode(job.sourceBytes);
  if (animation == null || job.frames.isEmpty) {
    throw const FormatException('The source GIF could not be decoded');
  }
  final sourceFrames = animation.frames;
  final overlay = switch (job.overlayRgba) {
    final bytes? => img.Image.fromBytes(
      width: job.width,
      height: job.height,
      bytes: bytes.buffer,
      bytesOffset: bytes.offsetInBytes,
      numChannels: 4,
    ),
    null => null,
  };
  final preparedFrames = <int, img.Image>{};
  final encoder = img.GifEncoder();
  for (final (position, frame) in job.frames.indexed) {
    final index = frame.sourceIndex.clamp(0, sourceFrames.length - 1);
    final image = preparedFrames[index] ??= _prepareFrame(
      sourceFrames[index],
      job,
      overlay,
    );
    encoder.addFrame(
      image,
      duration: frame.duration.inMilliseconds ~/ _millisecondsPerGifDelayUnit,
    );
    onProgress?.call((position + 1) / job.frames.length);
  }
  final output = encoder.finish();
  if (output == null) throw StateError('The GIF encoder produced no output');
  return output;
}

const int _millisecondsPerGifDelayUnit = 10;

img.Image _prepareFrame(
  img.Image source,
  RemixEncodeJob job,
  img.Image? overlay,
) {
  final resized = img.copyResize(
    source.convert(numChannels: 4),
    width: job.width,
    height: job.height,
    interpolation: img.Interpolation.average,
  );
  return overlay == null ? resized : img.compositeImage(resized, overlay);
}
