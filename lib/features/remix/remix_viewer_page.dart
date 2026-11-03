import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/media/share_file.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/confirm_dialog.dart';
import 'package:gif_loop/core/widgets/message_view.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/widgets/remix_hero_tag.dart';
import 'package:gif_loop/features/remix/widgets/remix_info_section.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';
import 'package:gif_loop/features/studio/widgets/gif_studio_controls.dart';
import 'package:gif_loop/features/studio/widgets/gif_studio_player.dart';

class RemixViewerPage extends StatelessWidget {
  const new({required this.remixId, super.key});

  final String remixId;

  @override
  Widget build(BuildContext context) {
    final remix = context.select<RemixesCubit, Remix?>(
      (cubit) => cubit.state.remixOf(remixId),
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: context.read<AppCoordinator>().back),
        title: const Text(Strings.myRemixes),
      ),
      body: SafeArea(
        top: false,
        child: remix == null
            ? const SingleChildScrollView(
                child: MessageView(
                  icon: Icons.search_off_rounded,
                  title: Strings.remixNotFoundTitle,
                  message: Strings.remixNotFoundMessage,
                ),
              )
            : _RemixViewer(key: ValueKey(remix.id), remix: remix),
      ),
    );
  }
}

class _RemixViewer extends StatefulWidget {
  const new({required this.remix, super.key});

  final Remix remix;

  @override
  State<_RemixViewer> createState() => _RemixViewerState();
}

class _RemixViewerState extends State<_RemixViewer>
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
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _load() => unawaited(
    _controller.load(
      file: widget.remix.file,
      autoplay: !MediaQuery.disableAnimationsOf(context),
    ),
  );

  Future<void> _delete() async {
    final remixes = context.read<RemixesCubit>();
    final coordinator = context.read<AppCoordinator>();
    final confirmed = await showConfirmDialog(
      context,
      title: Strings.deleteRemixTitle,
      message: Strings.deleteRemixMessage,
      confirmLabel: Strings.delete,
      cancelLabel: Strings.cancel,
    );
    if (!confirmed) return;
    coordinator.back();
    await remixes.delete(widget.remix);
  }

  @override
  Widget build(BuildContext context) {
    final remix = widget.remix;
    final player = GifStudioPlayer(
      controller: _controller,
      aspectRatio: remix.aspectRatio,
      heroTag: remixHeroTag(remix.id),
      semanticLabel: Strings.remixOf(remix.sourceTitle),
      placeholder: Image.file(remix.file, fit: BoxFit.contain),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.xl,
      children: [
        GifStudioControls(controller: _controller, onRetry: _load),
        RemixInfoSection(remix: remix),
        Wrap(
          spacing: Spacing.s,
          runSpacing: Spacing.s,
          children: [
            Builder(
              builder: (buttonContext) => FilledButton.tonalIcon(
                onPressed: () =>
                    unawaited(shareGifFile(buttonContext, remix.file)),
                icon: const Icon(Icons.share_rounded),
                label: const Text(Strings.share),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(Strings.delete),
            ),
          ],
        ),
      ],
    );
    return LayoutBuilder(
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
    );
  }
}
