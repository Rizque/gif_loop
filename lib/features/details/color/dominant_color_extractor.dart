import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gif_loop/core/media/image_bytes.dart';
import 'package:gif_loop/features/details/color/dominant_color.dart';

class DominantColorExtractor {
  const new(this._cacheManager);

  static const int _sampleWidth = 32;

  final BaseCacheManager _cacheManager;

  Future<ui.Color?> extract(String imageUrl, {File? localFile}) async {
    try {
      final file = localFile != null && localFile.existsSync()
          ? localFile
          : await _cacheManager.getSingleFile(imageUrl);
      final bytes = await file.readAsBytes();
      if (!isSupportedImage(bytes)) return null;
      final pixels = await _samplePixels(bytes);
      if (pixels == null) return null;
      final argb = await Isolate.run(() => dominantArgb(pixels));
      return argb == null ? null : ui.Color(argb);
    } on Exception {
      return null;
    }
  }

  Future<Uint8List?> _samplePixels(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: _sampleWidth,
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final data = await frame.image.toByteData();
        return data?.buffer.asUint8List();
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}
