import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gif_loop/features/details/color/dominant_color.dart';

class DominantColorExtractor {
  const new(this._cacheManager);

  static const int _sampleWidth = 32;

  final BaseCacheManager _cacheManager;

  Future<ui.Color?> extract(String imageUrl) async {
    try {
      final file = await _cacheManager.getSingleFile(imageUrl);
      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: _sampleWidth,
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      final data = await frame.image.toByteData();
      frame.image.dispose();
      if (data == null) return null;
      final pixels = data.buffer.asUint8List();
      final argb = await Isolate.run(() => dominantArgb(pixels));
      return argb == null ? null : ui.Color(argb);
    } on Exception {
      return null;
    }
  }
}
