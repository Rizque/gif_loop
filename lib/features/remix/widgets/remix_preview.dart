import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/export/caption_painter.dart';
import 'package:gif_loop/features/remix/widgets/remix_preview_controller.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';

class RemixPreview extends StatelessWidget {
  const new({
    required this.controller,
    required this.frames,
    required this.aspectRatio,
    super.key,
  });

  final RemixPreviewController controller;
  final List<GifFrame> frames;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final (topText, bottomText) = context
        .select<RemixEditorCubit, (String, String)>(
          (cubit) =>
              (cubit.state.settings.topText, cubit.state.settings.bottomText),
        );
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: controller.sourceIndex,
              builder: (context, index, _) => RawImage(
                image: frames[index.clamp(0, frames.length - 1)].image,
                fit: BoxFit.cover,
              ),
            ),
            CustomPaint(
              painter: CaptionPainter(topText: topText, bottomText: bottomText),
            ),
            Positioned(
              right: Spacing.s,
              bottom: Spacing.s,
              child: _PlayPauseButton(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const new({required this.controller});

  final RemixPreviewController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.hasPlayback) return const SizedBox.shrink();
      final isPlaying = controller.isPlaying;
      return IconButton.filledTonal(
        tooltip: isPlaying ? Strings.pause : Strings.play,
        onPressed: controller.togglePlay,
        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
      );
    },
  );
}
