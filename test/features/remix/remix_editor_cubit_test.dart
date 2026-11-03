import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/domain/remix_draft.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_state.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';

class _MockRemixExporter extends Mock implements RemixExporter;

const _frameDuration = Duration(milliseconds: 100);

void main() {
  late MockGifFrameLoader frameLoader;
  late _MockRemixExporter exporter;
  late MockLibraryRepository library;

  final gif = makeGif('abc');
  final sourceBytes = Uint8List.fromList([1, 2, 3]);
  final exportedBytes = Uint8List.fromList([4, 5, 6]);
  final remix = Remix(
    id: '1',
    sourceGifId: 'abc',
    sourceTitle: 'GIF abc',
    file: File('remixes/1.gif'),
    width: 480,
    height: 360,
    frameCount: 10,
    duration: const Duration(seconds: 1),
    sizeBytes: 3,
    createdAt: DateTime(2026),
  );

  setUpAll(() {
    registerTestFallbacks();
    registerFallbackValue(const RemixPlan([]));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue((width: 0, height: 0));
    registerFallbackValue(
      const RemixDraft(
        sourceGifId: '',
        sourceTitle: '',
        width: 0,
        height: 0,
        frameCount: 0,
        duration: Duration.zero,
      ),
    );
  });

  setUp(() {
    frameLoader = MockGifFrameLoader();
    exporter = _MockRemixExporter();
    library = MockLibraryRepository();
    when(() => library.favorite(any())).thenAnswer((_) async => null);
    when(
      () => frameLoader.loadBytes(
        url: any(named: 'url'),
        file: any(named: 'file'),
      ),
    ).thenAnswer((_) async => Success(sourceBytes));
    when(() => library.saveRemix(any(), any()))
        .thenAnswer((_) async => Success(remix));
  });

  void stubExport(
    Future<Result<Uint8List>> Function(
      CancellationToken cancellation,
      ValueChanged<double> onProgress,
    )
    answer,
  ) =>
      when(
        () => exporter.export(
          sourceBytes: any(named: 'sourceBytes'),
          plan: any(named: 'plan'),
          size: any(named: 'size'),
          topText: any(named: 'topText'),
          bottomText: any(named: 'bottomText'),
          onProgress: any(named: 'onProgress'),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer(
        (invocation) => answer(
          invocation.namedArguments[#cancellation] as CancellationToken,
          invocation.namedArguments[#onProgress] as ValueChanged<double>,
        ),
      );

  RemixEditorCubit buildReadyCubit({int frames = 10}) =>
      RemixEditorCubit(
        gif: gif,
        initialSettings: const StudioSettings(
          speed: 2,
          loopMode: LoopMode.reverse,
        ),
        frameLoader: frameLoader,
        exporter: exporter,
        libraryRepository: library,
      )..sourceReady(
        List.filled(frames, _frameDuration),
        decodedWidth: 240,
        decodedHeight: 180,
      );

  group('RemixEditorCubit', () {
    test('starts from the Studio settings and the full range', () {
      final state = buildReadyCubit().state;

      expect(state.settings.speed, 2);
      expect(state.settings.loopMode, LoopMode.reverse);
      expect(state.settings.trimStart, 0);
      expect(state.settings.trimEnd, 9);
      expect(state.plan.frames, hasLength(10));
      expect(state.hasUnsavedChanges, isFalse);
    });

    test('uses the original GIF size capped to the max width', () {
      final size = buildReadyCubit().state.outputSize;

      expect(size, (width: 480, height: 360));
      expect(RemixLimits.maxOutputWidth, 480);
    });

    test('marks changes as unsaved', () {
      final cubit = buildReadyCubit()..topTextChanged('hello');

      expect(cubit.state.hasUnsavedChanges, isTrue);
    });

    test('rebuilds the plan when trimming', () {
      final cubit = buildReadyCubit()..trimChanged(2, 5);

      expect(cubit.state.plan.frames, hasLength(4));
    });

    test('cannot export above the frame cap', () {
      final cubit = buildReadyCubit(frames: RemixLimits.maxOutputFrames + 1);

      expect(cubit.state.plan.exceedsFrameLimit, isTrue);
      expect(cubit.state.canExport, isFalse);
    });

    test('exports, reports progress and saves to the library', () async {
      stubExport((cancellation, onProgress) async {
        onProgress(0.5);
        return Success(exportedBytes);
      });
      final cubit = buildReadyCubit();
      final progress = <double>[];
      final subscription = cubit.stream.listen(
        (state) => progress.add(state.exportProgress),
      );

      await cubit.export();
      await subscription.cancel();

      expect(cubit.state.exportStatus, RemixExportStatus.success);
      expect(cubit.state.exportedRemix, remix);
      expect(cubit.state.hasUnsavedChanges, isFalse);
      expect(progress, contains(0.5));
      final draft =
          verify(() => library.saveRemix(exportedBytes, captureAny()))
                  .captured
                  .single
              as RemixDraft;
      expect(draft.sourceGifId, 'abc');
      expect(draft.width, 480);
      expect(draft.frameCount, 10);
    });

    test('cancelling an export saves nothing', () async {
      final finished = Completer<Result<Uint8List>>();
      stubExport((cancellation, onProgress) {
        unawaited(
          cancellation.whenCancelled.then(
            (_) => finished.complete(const Err(UnknownFailure())),
          ),
        );
        return finished.future;
      });
      final cubit = buildReadyCubit();

      final exporting = cubit.export();
      await pumpEventQueue();
      cubit.cancelExport();
      await exporting;

      expect(cubit.state.exportStatus, RemixExportStatus.idle);
      verifyNever(() => library.saveRemix(any(), any()));
    });

    test('an encoding error shows a failure and saves nothing', () async {
      stubExport(
        (cancellation, onProgress) async => const Err(DecodingFailure()),
      );
      final cubit = buildReadyCubit();

      await cubit.export();

      expect(cubit.state.exportStatus, RemixExportStatus.failure);
      expect(cubit.state.exportFailure, const DecodingFailure());
      verifyNever(() => library.saveRemix(any(), any()));
    });
  });
}
