import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';

class GifNetworkImage extends StatelessWidget {
  const new({
    required this.rendition,
    required this.placeholderColor,
    super.key,
    this.fit = BoxFit.cover,
  });

  final GifRendition rendition;
  final Color placeholderColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: rendition.url,
    fit: fit,
    fadeInDuration: AppDurations.short,
    placeholder: (context, url) => ColoredBox(color: placeholderColor),
    errorWidget: (context, url, error) => ColoredBox(
      color: placeholderColor,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70),
      ),
    ),
  );
}
