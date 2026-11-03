import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:gif_loop/features/library/domain/remix_draft.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_state.dart';
import 'package:gif_loop/features/remix/domain/remix_settings.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';

class RemixEditorCubit extends Cubit<RemixEditorState> {
  new({
    required this._gif,
    required StudioSettings initialSettings,
    required this._frameLoader,
    required this._exporter,
    required this._libraryRepository,
  }) : super(
         RemixEditorState(
           settings: _settingsFrom(initialSettings),
           initialSettings: _settingsFrom(initialSettings),
         ),
       );

  final Gif _gif;
  final GifFrameLoader _frameLoader;
  final RemixExporter _exporter;
  final LibraryRepository _libraryRepository;
  List<Duration> _sourceDurations = const [];
  CancellationToken? _export;

  static RemixSettings _settingsFrom(StudioSettings studio) => RemixSettings(
    trimStart: 0,
    trimEnd: 0,
    speed: studio.speed,
    loopMode: studio.loopMode,
  );

  // GIPHY's metadata has the original size; the decoded frames may have been
  // scaled down to fit the Studio's memory budget.
  void sourceReady(
    List<Duration> durations, {
    required int decodedWidth,
    required int decodedHeight,
  }) {
    _sourceDurations = durations;
    final hasMetadataSize = _gif.full.width > 0 && _gif.full.height > 0;
    final trimmed = state.settings.copyWith(trimEnd: durations.length - 1);
    emit(
      state.copyWith(
        settings: trimmed,
        initialSettings: state.initialSettings.copyWith(
          trimEnd: durations.length - 1,
        ),
        plan: RemixPlan.build(durations, trimmed),
        outputSize: remixOutputSize(
          width: hasMetadataSize ? _gif.full.width : decodedWidth,
          height: hasMetadataSize ? _gif.full.height : decodedHeight,
        ),
      ),
    );
  }

  void trimChanged(int start, int end) =>
      _update(state.settings.copyWith(trimStart: start, trimEnd: end));

  void speedChanged(double speed) =>
      _update(state.settings.copyWith(speed: speed));

  void loopModeChanged(LoopMode mode) =>
      _update(state.settings.copyWith(loopMode: mode));

  void topTextChanged(String text) =>
      _update(state.settings.copyWith(topText: text));

  void bottomTextChanged(String text) =>
      _update(state.settings.copyWith(bottomText: text));

  Future<void> export() async {
    final outputSize = state.outputSize;
    if (!state.canExport || outputSize == null) return;
    final cancellation = _export = CancellationToken();
    final plan = state.plan;
    final settings = state.settings;
    emit(
      state.copyWith(
        exportStatus: RemixExportStatus.exporting,
        exportProgress: 0,
      ),
    );
    final favorite = await _libraryRepository.favorite(_gif.id);
    final source = await _frameLoader.loadBytes(
      url: _gif.full.url,
      file: favorite?.fullFile,
    );
    if (cancellation.isCancelled || isClosed) return;
    final Uint8List sourceBytes;
    switch (source) {
      case Success(:final value):
        sourceBytes = value;
      case Err(:final failure):
        return _fail(failure);
    }
    final encoded = await _exporter.export(
      sourceBytes: sourceBytes,
      plan: plan,
      size: outputSize,
      topText: settings.topText,
      bottomText: settings.bottomText,
      cancellation: cancellation,
      onProgress: (progress) {
        if (!cancellation.isCancelled && !isClosed) {
          emit(state.copyWith(exportProgress: progress));
        }
      },
    );
    if (cancellation.isCancelled || isClosed) return;
    final Uint8List gifBytes;
    switch (encoded) {
      case Success(:final value):
        gifBytes = value;
      case Err(:final failure):
        return _fail(failure);
    }
    final saved = await _libraryRepository.saveRemix(
      gifBytes,
      RemixDraft(
        sourceGifId: _gif.id,
        sourceTitle: _gif.title,
        width: outputSize.width,
        height: outputSize.height,
        frameCount: plan.frames.length,
        duration: plan.duration,
      ),
    );
    if (isClosed) return;
    switch (saved) {
      case Success(value: final remix):
        emit(
          state.copyWith(
            exportStatus: RemixExportStatus.success,
            exportProgress: 1,
            exportedRemix: remix,
          ),
        );
      case Err(:final failure):
        _fail(failure);
    }
  }

  void cancelExport() {
    _export?.cancel();
    emit(state.copyWith(exportStatus: RemixExportStatus.idle));
  }

  void dismissExport() =>
      emit(state.copyWith(exportStatus: RemixExportStatus.idle));

  void _fail(Failure failure) => emit(
    state.copyWith(
      exportStatus: RemixExportStatus.failure,
      exportFailure: failure,
    ),
  );

  void _update(RemixSettings settings) => emit(
    state.copyWith(
      settings: settings,
      plan: RemixPlan.build(_sourceDurations, settings),
    ),
  );

  @override
  Future<void> close() {
    _export?.cancel();
    return super.close();
  }
}
