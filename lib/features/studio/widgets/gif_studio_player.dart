import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';

class GifStudioPlayer extends StatelessWidget {
  const new({
    required this.controller,
    required this.aspectRatio,
    required this.heroTag,
    required this.semanticLabel,
    required this.placeholder,
    super.key,
  });

  final GifStudioController controller;
  final double aspectRatio;
  final Object heroTag;
  final String semanticLabel;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: aspectRatio,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: Hero(
        tag: heroTag,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final isReady = controller.status == StudioStatus.ready;
            return Semantics(
              button: controller.hasPlayback,
              label: semanticLabel,
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
                      : KeyedSubtree(
                          key: const ValueKey('placeholder'),
                          child: placeholder,
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
