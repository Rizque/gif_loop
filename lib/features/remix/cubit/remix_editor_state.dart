import 'package:equatable/equatable.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/remix/domain/remix_settings.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';

enum RemixExportStatus { idle, exporting, success, failure }

class RemixEditorState extends Equatable {
  const new({
    required this.settings,
    required this.initialSettings,
    this.plan = const RemixPlan([]),
    this.outputSize,
    this.exportStatus = RemixExportStatus.idle,
    this.exportProgress = 0,
    this.exportedRemix,
    this.exportFailure,
  });

  final RemixSettings settings;
  final RemixSettings initialSettings;
  final RemixPlan plan;
  final RemixSize? outputSize;
  final RemixExportStatus exportStatus;
  final double exportProgress;
  final Remix? exportedRemix;
  final Failure? exportFailure;

  bool get isSourceReady => outputSize != null;

  bool get hasUnsavedChanges =>
      settings != initialSettings && exportedRemix == null;

  bool get canExport =>
      isSourceReady &&
      plan.frames.isNotEmpty &&
      !plan.exceedsFrameLimit &&
      exportStatus != RemixExportStatus.exporting;

  RemixEditorState copyWith({
    RemixSettings? settings,
    RemixSettings? initialSettings,
    RemixPlan? plan,
    RemixSize? outputSize,
    RemixExportStatus? exportStatus,
    double? exportProgress,
    Remix? exportedRemix,
    Failure? exportFailure,
  }) => RemixEditorState(
    settings: settings ?? this.settings,
    initialSettings: initialSettings ?? this.initialSettings,
    plan: plan ?? this.plan,
    outputSize: outputSize ?? this.outputSize,
    exportStatus: exportStatus ?? this.exportStatus,
    exportProgress: exportProgress ?? this.exportProgress,
    exportedRemix: exportedRemix ?? this.exportedRemix,
    exportFailure: exportFailure,
  );

  @override
  List<Object?> get props => [
    settings,
    initialSettings,
    plan,
    outputSize,
    exportStatus,
    exportProgress,
    exportedRemix,
    exportFailure,
  ];
}
