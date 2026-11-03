import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gif_loop/core/config/breakpoints.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/theme/tile_palette.dart';
import 'package:gif_loop/features/feed/widgets/gif_tile.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class GifMasonryGrid extends StatelessWidget {
  const new({required this.items, required this.onGifTap, super.key});

  final List<Gif> items;
  final ValueChanged<Gif> onGifTap;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) => SliverMasonryGrid.count(
        crossAxisCount: Breakpoints.gridColumnCount(
          constraints.crossAxisExtent,
        ),
        mainAxisSpacing: Spacing.s,
        crossAxisSpacing: Spacing.s,
        childCount: items.length,
        itemBuilder: (context, index) {
          final gif = items[index];
          return GifTile(
            key: ValueKey(gif.id),
            gif: gif,
            placeholderColor: TilePalette.colorAt(index),
            onTap: () => onGifTap(gif),
          );
        },
      ),
    ),
  );
}
