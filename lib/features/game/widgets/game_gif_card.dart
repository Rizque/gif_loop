import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/theme/tile_palette.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_hero_tag.dart';
import 'package:gif_loop/features/gifs/widgets/gif_network_image.dart';

class GameGifCard extends StatelessWidget {
  const new({
    required this.gif,
    required this.isRevealed,
    required this.onOpenDetails,
    super.key,
  });

  final Gif gif;
  final bool isRevealed;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) => Semantics(
    label: isRevealed ? gif.title : Strings.mysteryGif,
    button: isRevealed,
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: gif.preview.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: gifHeroTag(gif.id),
              child: GifNetworkImage(
                rendition: gif.preview,
                placeholderColor: TilePalette.colorAt(gif.id.hashCode),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: isRevealed ? onOpenDetails : null),
            ),
          ],
        ),
      ),
    ),
  );
}
