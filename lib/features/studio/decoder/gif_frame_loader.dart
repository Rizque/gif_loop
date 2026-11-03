import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_mapper.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/memory_budget.dart';

class GifFrameLoader {
  const new(this._cacheManager);

  static const int memoryBudgetBytes = 120 * 1024 * 1024;

  final BaseCacheManager _cacheManager;

  Future<Result<List<GifFrame>>> load({
    required CancellationToken cancellation,
    required ValueChanged<double> onProgress,
    String? url,
    File? file,
  }) async {
    final bytes = await loadBytes(url: url, file: file);
    if (cancellation.isCancelled) return const Err(UnknownFailure());
    return switch (bytes) {
      Success(value: final bytes) => await _decode(
        bytes,
        cancellation,
        onProgress,
      ),
      Err(:final failure) => Err(failure),
    };
  }

  // A local file (favorite or remix) wins over the network so it works
  // offline; the url is the fallback if the file is missing.
  Future<Result<Uint8List>> loadBytes({String? url, File? file}) async {
    try {
      final source = file != null && file.existsSync()
          ? file
          : await _cacheManager.getSingleFile(url ?? '');
      return Success(await source.readAsBytes());
    } on Exception catch (error) {
      return Err(mapMediaError(error));
    }
  }

  Future<Result<List<GifFrame>>> _decode(
    Uint8List bytes,
    CancellationToken cancellation,
    ValueChanged<double> onProgress,
  ) async {
    final frames = <GifFrame>[];
    ui.Codec? codec;
    try {
      codec = await _instantiateCodec(bytes);
      for (var i = 0; i < codec.frameCount; i++) {
        if (cancellation.isCancelled) {
          _dispose(frames);
          return const Err(UnknownFailure());
        }
        final frame = await codec.getNextFrame();
        frames.add(GifFrame(frame.image, frame.duration));
        onProgress((i + 1) / codec.frameCount);
      }
      return Success(frames);
    } on Exception {
      _dispose(frames);
      return const Err(DecodingFailure());
    } finally {
      codec?.dispose();
    }
  }

  Future<ui.Codec> _instantiateCodec(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    buffer.dispose();
    try {
      final codec = await descriptor.instantiateCodec();
      final targetWidth = targetWidthWithinBudget(
        width: descriptor.width,
        height: descriptor.height,
        frameCount: codec.frameCount,
        budgetBytes: memoryBudgetBytes,
      );
      if (targetWidth == null) return codec;
      codec.dispose();
      return await descriptor.instantiateCodec(targetWidth: targetWidth);
    } finally {
      descriptor.dispose();
    }
  }

  static void _dispose(List<GifFrame> frames) {
    for (final frame in frames) {
      frame.image.dispose();
    }
  }
}
