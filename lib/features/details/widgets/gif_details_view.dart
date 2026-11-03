import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/giphy_attribution.dart';
import 'package:gif_loop/features/details/widgets/gif_actions.dart';
import 'package:gif_loop/features/details/widgets/gif_info_section.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';
import 'package:gif_loop/features/studio/widgets/gif_studio_controls.dart';
import 'package:gif_loop/features/studio/widgets/gif_studio_player.dart';

class GifDetailsView extends StatefulWidget {
  const new({required this.gif, super.key});

  final Gif gif;

  @override
  State<GifDetailsView> createState() => _GifDetailsViewState();
}

class _GifDetailsViewState extends State<GifDetailsView>
    with SingleTickerProviderStateMixin {
  static const double _landscapeMinWidth = 520;
  static const double _portraitPlayerMaxHeightFactor = 0.55;

  late final GifStudioController _controller = GifStudioController(
    vsync: this,
    loader: context.read<GifFrameLoader>(),
  );

  @override
  void initState() {
    super.initState();
    _loadFrames();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadFrames() => unawaited(
    _controller.load(url: widget.gif.full.url, file: _favorite?.fullFile),
  );

  FavoriteGif? get _favorite =>
      context.read<FavoritesCubit>().state.favoriteOf(widget.gif.id);

  void _retryAfterReconnect() {
    if (_controller.status == StudioStatus.failure &&
        (_controller.failure?.isTransient ?? false)) {
      _loadFrames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = GifStudioPlayer(
      gif: widget.gif,
      controller: _controller,
      previewFile: context.select<FavoritesCubit, File?>(
        (cubit) => cubit.state.favoriteOf(widget.gif.id)?.previewFile,
      ),
    );
    final details = _DetailsColumn(
      gif: widget.gif,
      controls: GifStudioControls(
        controller: _controller,
        onRetry: _loadFrames,
      ),
    );
    return ReconnectListener(
      onReconnected: _retryAfterReconnect,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape =
              constraints.maxWidth > constraints.maxHeight &&
              constraints.maxWidth >= _landscapeMinWidth;
          if (isLandscape) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.l),
                    child: Center(child: player),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Spacing.l),
                    child: details,
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.l),
            child: Column(
              spacing: Spacing.l,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        constraints.maxHeight * _portraitPlayerMaxHeightFactor,
                  ),
                  child: player,
                ),
                details,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailsColumn extends StatelessWidget {
  const new({required this.gif, required this.controls});

  final Gif gif;
  final Widget controls;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Spacing.xl,
    children: [
      controls,
      GifInfoSection(gif: gif),
      GifActions(gif: gif),
      const Center(child: GiphyAttribution()),
    ],
  );
}
