import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/theme/tile_palette.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_hero_tag.dart';
import 'package:gif_loop/features/gifs/widgets/gif_network_image.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';

class GifStudioPlayer extends StatelessWidget {
  const new({required this.gif, required this.controller, super.key});

  final Gif gif;
  final GifStudioController controller;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: gif.preview.aspectRatio,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: Hero(
        tag: gifHeroTag(gif.id),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final isReady = controller.status == StudioStatus.ready;
            return Semantics(
              button: controller.hasPlayback,
              label: gif.title,
              hint: controller.hasPlayback
                  ? (controller.isPlaying ? Strings.pause : Strings.play)
                  : null,
              child: GestureDetector(
                onTap: controller.hasPlayback ? controller.togglePlay : null,
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  child: isReady
                      ? _CurrentFrame(
                          key: const ValueKey('frames'),
                          controller: controller,
                        )
                      : GifNetworkImage(
                          key: const ValueKey('preview'),
                          rendition: gif.preview,
                          placeholderColor: TilePalette.colorAt(0),
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _CurrentFrame extends StatelessWidget {
  const new({required this.controller, super.key});

  final GifStudioController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: controller.frameIndex,
    builder: (context, _, _) => RawImage(
      image: controller.currentImage,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    ),
  );
}
