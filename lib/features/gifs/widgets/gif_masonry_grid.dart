import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/tile_palette.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_tile.dart';
import 'package:gif_loop/features/gifs/widgets/masonry_grid_sliver.dart';

class GifMasonryGrid extends StatelessWidget {
  const new({
    required this.items,
    required this.onGifTap,
    super.key,
    this.previewFileOf,
  });

  final List<Gif> items;
  final ValueChanged<Gif> onGifTap;
  final File? Function(Gif gif)? previewFileOf;

  @override
  Widget build(BuildContext context) => MasonryGridSliver(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final gif = items[index];
      return GifTile(
        key: ValueKey(gif.id),
        gif: gif,
        previewFile: previewFileOf?.call(gif),
        placeholderColor: TilePalette.colorAt(index),
        onTap: () => onGifTap(gif),
      );
    },
  );
}
