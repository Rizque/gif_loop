import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_hero_tag.dart';
import 'package:gif_loop/features/gifs/widgets/gif_image.dart';
import 'package:gif_loop/features/gifs/widgets/tappable_tile.dart';

class GifTile extends StatelessWidget {
  const new({
    required this.gif,
    required this.placeholderColor,
    required this.onTap,
    super.key,
    this.previewFile,
  });

  final Gif gif;
  final Color placeholderColor;
  final VoidCallback onTap;
  final File? previewFile;

  @override
  Widget build(BuildContext context) => TappableTile(
    aspectRatio: gif.preview.aspectRatio,
    semanticLabel: gif.title,
    heroTag: gifHeroTag(gif.id),
    onTap: onTap,
    child: GifImage(
      rendition: gif.preview,
      file: previewFile,
      placeholderColor: placeholderColor,
    ),
  );
}
