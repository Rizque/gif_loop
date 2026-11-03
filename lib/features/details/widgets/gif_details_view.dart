import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/theme/tile_palette.dart';
import 'package:gif_loop/core/widgets/giphy_attribution.dart';
import 'package:gif_loop/features/details/widgets/gif_actions.dart';
import 'package:gif_loop/features/details/widgets/gif_info_section.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_hero_tag.dart';
import 'package:gif_loop/features/gifs/widgets/gif_image.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
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

  bool _isLoadStarted = false;

  // The first load needs MediaQuery (reduce motion), so it waits for
  // didChangeDependencies instead of initState.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoadStarted) return;
    _isLoadStarted = true;
    _loadFrames();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadFrames() => unawaited(
    _controller.load(
      url: widget.gif.full.url,
      file: _favorite?.fullFile,
      autoplay: !MediaQuery.disableAnimationsOf(context),
    ),
  );

  FavoriteGif? get _favorite =>
      context.read<FavoritesCubit>().state.favoriteOf(widget.gif.id);

  // The editor starts from the speed and loop mode chosen in the Studio.
  void _openRemixEditor() {
    _controller.pause();
    context.read<AppCoordinator>().showRemixEditor(
      widget.gif,
      StudioSettings(speed: _controller.speed, loopMode: _controller.loopMode),
    );
  }

  void _retryAfterReconnect() {
    if (_controller.status == StudioStatus.failure &&
        (_controller.failure?.isTransient ?? false)) {
      _loadFrames();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gif = widget.gif;
    final player = GifStudioPlayer(
      controller: _controller,
      aspectRatio: gif.preview.aspectRatio,
      heroTag: gifHeroTag(gif.id),
      semanticLabel: gif.title,
      placeholder: GifImage(
        rendition: gif.preview,
        file: context.select<FavoritesCubit, File?>(
          (cubit) => cubit.state.favoriteOf(gif.id)?.previewFile,
        ),
        placeholderColor: TilePalette.colorAt(0),
        fit: BoxFit.contain,
      ),
    );
    final details = _DetailsColumn(
      gif: widget.gif,
      onRemix: _openRemixEditor,
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
  const new({required this.gif, required this.onRemix, required this.controls});

  final Gif gif;
  final VoidCallback onRemix;
  final Widget controls;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Spacing.xl,
    children: [
      controls,
      GifInfoSection(gif: gif),
      GifActions(gif: gif, onRemix: onRemix),
      const Center(child: GiphyAttribution()),
    ],
  );
}
