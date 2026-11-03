import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_hero_tag.dart';
import 'package:gif_loop/features/gifs/widgets/gif_network_image.dart';

class GifTile extends StatelessWidget {
  const new({
    required this.gif,
    required this.placeholderColor,
    required this.onTap,
    super.key,
  });

  final Gif gif;
  final Color placeholderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: gif.title,
    button: true,
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: gif.preview.aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.tile),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: gifHeroTag(gif.id),
              child: GifNetworkImage(
                rendition: gif.preview,
                placeholderColor: placeholderColor,
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    ),
  );
}
