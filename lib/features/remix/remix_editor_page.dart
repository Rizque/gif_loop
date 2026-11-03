import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/confirm_dialog.dart';
import 'package:gif_loop/core/widgets/error_view.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/library/library_segment.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_state.dart';
import 'package:gif_loop/features/remix/widgets/remix_controls.dart';
import 'package:gif_loop/features/remix/widgets/remix_export_dialog.dart';
import 'package:gif_loop/features/remix/widgets/remix_preview.dart';
import 'package:gif_loop/features/remix/widgets/remix_preview_controller.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';
import 'package:gif_loop/features/studio/widgets/gif_studio_controls.dart';

class RemixEditorPage extends StatefulWidget {
  const new({required this.gif, super.key});

  final Gif gif;

  @override
  State<RemixEditorPage> createState() => _RemixEditorPageState();
}

class _RemixEditorPageState extends State<RemixEditorPage>
    with TickerProviderStateMixin {
  late final GifStudioController _source = GifStudioController(
    vsync: this,
    loader: context.read<GifFrameLoader>(),
  );
  late final RemixPreviewController _preview = RemixPreviewController(
    vsync: this,
  );
  bool _isSourceReported = false;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _source.addListener(_onSourceChanged);
    _loadSource();
  }

  @override
  void dispose() {
    _source
      ..removeListener(_onSourceChanged)
      ..dispose();
    _preview.dispose();
    super.dispose();
  }

  void _loadSource() {
    final favorite = context.read<FavoritesCubit>().state.favoriteOf(
      widget.gif.id,
    );
    unawaited(
      _source.load(
        url: widget.gif.full.url,
        file: favorite?.fullFile,
        autoplay: false,
      ),
    );
  }

  void _onSourceChanged() {
    if (_isSourceReported || _source.status != StudioStatus.ready) return;
    _isSourceReported = true;
    final frames = _source.frames;
    context.read<RemixEditorCubit>().sourceReady(
      [for (final frame in frames) frame.duration],
      decodedWidth: frames.first.image.width,
      decodedHeight: frames.first.image.height,
    );
  }

  void _retryAfterReconnect() {
    if (_source.status == StudioStatus.failure &&
        (_source.failure?.isTransient ?? false)) {
      _loadSource();
    }
  }

  Future<void> _confirmLeave() async {
    final discard = await showConfirmDialog(
      context,
      title: Strings.discardChangesTitle,
      message: Strings.discardChangesMessage,
      confirmLabel: Strings.discard,
      cancelLabel: Strings.keepEditing,
    );
    if (discard && mounted) _leave(context.read<AppCoordinator>().back);
  }

  // PopScope must allow the pop before the coordinator performs it.
  void _leave(VoidCallback navigate) {
    setState(() => _isLeaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
  }

  Future<void> _onExportStarted() async {
    final coordinator = context.read<AppCoordinator>();
    final exit = await showRemixExportDialog(context);
    if (!mounted) return;
    switch (exit) {
      case RemixExportExit.stay:
        break;
      case RemixExportExit.leaveEditor:
        _leave(coordinator.back);
      case RemixExportExit.viewInLibrary:
        _leave(() => coordinator.showLibrary(segment: LibrarySegment.remixes));
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<RemixEditorCubit, RemixEditorState>(
        listenWhen: (previous, current) => previous.plan != current.plan,
        listener: (context, state) => _preview.showPlan(state.plan),
      ),
      BlocListener<RemixEditorCubit, RemixEditorState>(
        listenWhen: (previous, current) =>
            previous.exportStatus == RemixExportStatus.idle &&
            current.exportStatus == RemixExportStatus.exporting,
        listener: (context, state) => unawaited(_onExportStarted()),
      ),
      BlocListener<RemixEditorCubit, RemixEditorState>(
        listenWhen: (previous, current) =>
            previous.exportedRemix != current.exportedRemix,
        listener: (context, state) {
          if (state.exportedRemix case final remix?) {
            context.read<RemixesCubit>().added(remix);
          }
        },
      ),
    ],
    child: BlocSelector<RemixEditorCubit, RemixEditorState, bool>(
      selector: (state) => state.hasUnsavedChanges,
      builder: (context, hasUnsavedChanges) => PopScope(
        canPop: !hasUnsavedChanges || _isLeaving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_confirmLeave());
        },
        child: ReconnectListener(
          onReconnected: _retryAfterReconnect,
          child: Scaffold(
            appBar: AppBar(title: const Text(Strings.remixEditorTitle)),
            body: SafeArea(
              top: false,
              child: ListenableBuilder(
                listenable: _source,
                builder: (context, _) => switch (_source.status) {
                  StudioStatus.loading => Padding(
                    padding: const EdgeInsets.all(Spacing.xl),
                    child: Center(
                      child: GifStudioControls(
                        controller: _source,
                        onRetry: _loadSource,
                      ),
                    ),
                  ),
                  StudioStatus.failure => ErrorView(
                    failure: _source.failure ?? const UnknownFailure(),
                    onRetry: _loadSource,
                  ),
                  StudioStatus.ready => _EditorLayout(
                    source: _source,
                    preview: _preview,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _EditorLayout extends StatelessWidget {
  const new({required this.source, required this.preview});

  static const double _landscapeMinWidth = 520;
  static const double _portraitPreviewMaxHeightFactor = 0.45;

  final GifStudioController source;
  final RemixPreviewController preview;

  @override
  Widget build(BuildContext context) {
    final outputSize = context.select<RemixEditorCubit, (int, int)?>(
      (cubit) => switch (cubit.state.outputSize) {
        final size? => (size.width, size.height),
        null => null,
      },
    );
    final (width, height) = outputSize ?? (1, 1);
    final previewWidget = RemixPreview(
      controller: preview,
      frames: source.frames,
      aspectRatio: width / height,
    );
    final controls = RemixControls(
      sourceFrameCount: source.frameCount,
      preview: preview,
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
                  child: Center(child: previewWidget),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.l),
                  child: controls,
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
                      constraints.maxHeight * _portraitPreviewMaxHeightFactor,
                ),
                child: previewWidget,
              ),
              controls,
            ],
          ),
        );
      },
    );
  }
}
