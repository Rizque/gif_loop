import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/media/share_file.dart';
import 'package:gif_loop/core/platform/adaptive_dialog_action.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_state.dart';

enum RemixExportExit { stay, leaveEditor, viewInLibrary }

Future<RemixExportExit> showRemixExportDialog(BuildContext context) async {
  final cubit = context.read<RemixEditorCubit>();
  final exit = await showAdaptiveDialog<RemixExportExit>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const RemixExportDialog()),
  );
  return exit ?? RemixExportExit.stay;
}

class RemixExportDialog extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<RemixEditorCubit, RemixEditorState>(
        listenWhen: (previous, current) =>
            current.exportStatus == RemixExportStatus.idle,
        listener: (context, _) =>
            Navigator.of(context).pop(RemixExportExit.stay),
        builder: (context, state) => PopScope(
          canPop: false,
          child: switch (state) {
            RemixEditorState(
              exportStatus: RemixExportStatus.success,
              exportedRemix: final remix?,
            ) =>
              _ExportSuccess(remix: remix),
            RemixEditorState(exportStatus: RemixExportStatus.failure) =>
              _ExportFailure(
                failure: state.exportFailure ?? const UnknownFailure(),
              ),
            RemixEditorState() => _ExportProgress(
              progress: state.exportProgress,
            ),
          },
        ),
      );
}

class _ExportProgress extends StatelessWidget {
  const new({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: Text(Strings.exporting((progress * 100).round())),
    content: Padding(
      padding: const EdgeInsets.only(top: Spacing.m),
      child: LinearProgressIndicator(value: progress),
    ),
    actions: [
      AdaptiveDialogAction(
        label: Strings.cancel,
        isDestructive: true,
        onPressed: context.read<RemixEditorCubit>().cancelExport,
      ),
    ],
  );
}

class _ExportSuccess extends StatelessWidget {
  const new({required this.remix});

  static const double _thumbnailMaxHeight = 160;

  final Remix remix;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: const Text(Strings.savedToLibrary),
    content: Padding(
      padding: const EdgeInsets.only(top: Spacing.m),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _thumbnailMaxHeight),
        child: AspectRatio(
          aspectRatio: remix.aspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.tile),
            child: Image.file(remix.file, fit: BoxFit.cover),
          ),
        ),
      ),
    ),
    actions: [
      Builder(
        builder: (buttonContext) => AdaptiveDialogAction(
          label: Strings.share,
          onPressed: () => unawaited(shareGifFile(buttonContext, remix.file)),
        ),
      ),
      AdaptiveDialogAction(
        label: Strings.viewInLibrary,
        onPressed: () =>
            Navigator.of(context).pop(RemixExportExit.viewInLibrary),
      ),
      AdaptiveDialogAction(
        label: Strings.done,
        isDefault: true,
        onPressed: () => Navigator.of(context).pop(RemixExportExit.leaveEditor),
      ),
    ],
  );
}

class _ExportFailure extends StatelessWidget {
  const new({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemixEditorCubit>();
    return AlertDialog.adaptive(
      title: Text(failure.title),
      content: Text(failure.message),
      actions: [
        AdaptiveDialogAction(
          label: Strings.close,
          onPressed: cubit.dismissExport,
        ),
        AdaptiveDialogAction(
          label: Strings.retry,
          isDefault: true,
          onPressed: cubit.export,
        ),
      ],
    );
  }
}
