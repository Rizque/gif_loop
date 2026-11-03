import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';

class GifImage extends StatelessWidget {
  const new({
    required this.rendition,
    required this.placeholderColor,
    super.key,
    this.file,
    this.fit = BoxFit.cover,
  });

  final GifRendition rendition;
  final Color placeholderColor;
  final File? file;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final file = this.file;
    if (file != null) {
      return Image.file(
        file,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) =>
            _BrokenImage(color: placeholderColor),
      );
    }
    return CachedNetworkImage(
      imageUrl: rendition.url,
      fit: fit,
      fadeInDuration: AppDurations.short,
      placeholder: (context, url) => ColoredBox(color: placeholderColor),
      errorWidget: (context, url, error) =>
          _BrokenImage(color: placeholderColor),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: color,
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white70),
    ),
  );
}
