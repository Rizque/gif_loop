import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixture.dart';
import '../../helpers/mocks.dart';

const _frameDuration = Duration(milliseconds: 100);

void main() {
  late MockGifFrameLoader loader;

  setUpAll(registerTestFallbacks);

  setUp(() => loader = MockGifFrameLoader());

  Future<List<GifFrame>> decodeFrames(WidgetTester tester, int count) async {
    final frames = <GifFrame>[];
    for (var i = 0; i < count; i++) {
      final image = await tester.runAsync(() => createTestImage(cache: false));
      frames.add(GifFrame(image!, _frameDuration));
    }
    return frames;
  }

  void stubLoad(Result<List<GifFrame>> result) {
    when(
      () => loader.load(
        url: any(named: 'url'),
        file: any(named: 'file'),
        cancellation: any(named: 'cancellation'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) async {
      (invocation.namedArguments[#onProgress] as ValueChanged<double>)(1);
      return result;
    });
  }

  Future<GifStudioController> loadedController(
    WidgetTester tester, {
    required int frames,
  }) async {
    stubLoad(Success(await decodeFrames(tester, frames)));
    final controller = GifStudioController(vsync: tester, loader: loader);
    await controller.load(url: 'https://media.giphy.com/media/abc/giphy.gif');
    return controller;
  }

  testWidgets('starts playing once frames are decoded', (tester) async {
    final controller = await loadedController(tester, frames: 3);

    expect(controller.status, StudioStatus.ready);
    expect(controller.progress, 1);
    expect(controller.frameCount, 3);
    expect(controller.isPlaying, isTrue);

    await tester.pump();
    await tester.pump(_frameDuration);
    expect(controller.frameIndex.value, 1);

    await tester.pump(_frameDuration);
    expect(controller.frameIndex.value, 2);

    controller.dispose();
  });

  testWidgets('applies speed and loop mode to playback', (tester) async {
    final controller = await loadedController(tester, frames: 4)
      ..speed = 2
      ..loopMode = LoopMode.reverse;

    await tester.pump();
    await tester.pump(_frameDuration);

    expect(controller.frameIndex.value, 2);
    controller.dispose();
  });

  testWidgets('seeking pauses playback on the chosen frame', (tester) async {
    final controller = await loadedController(tester, frames: 5)
      ..seek(3);

    expect(controller.isPlaying, isFalse);
    expect(controller.frameIndex.value, 3);

    await tester.pump(_frameDuration * 3);
    expect(controller.frameIndex.value, 3);
    controller.dispose();
  });

  testWidgets('steps frames only while paused', (tester) async {
    final controller = await loadedController(tester, frames: 3)
      ..stepForward();
    expect(controller.frameIndex.value, 0);

    controller
      ..pause()
      ..stepForward()
      ..stepForward()
      ..stepForward();
    expect(controller.frameIndex.value, 0);

    controller.stepBackward();
    expect(controller.frameIndex.value, 2);
    controller.dispose();
  });

  testWidgets('a single-frame GIF has no playback', (tester) async {
    final controller = await loadedController(tester, frames: 1)
      ..play();

    expect(controller.hasPlayback, isFalse);
    expect(controller.isPlaying, isFalse);
    controller.dispose();
  });

  group('with a really decoded single-frame GIF', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('studio_controller');
    });

    tearDown(() => directory.deleteSync(recursive: true));

    Future<GifStudioController> loadFixture(WidgetTester tester) async {
      final file = File('${directory.path}/still.gif')
        ..writeAsBytesSync(singleFrameGif());
      final controller = GifStudioController(
        vsync: tester,
        loader: GifFrameLoader(MockCacheManager()),
      );
      await tester.runAsync(() => controller.load(file: file));
      return controller;
    }

    testWidgets('shows the frame and never starts the ticker', (tester) async {
      final controller = await loadFixture(tester);

      expect(controller.status, StudioStatus.ready);
      expect(controller.frameCount, 1);
      expect(controller.hasPlayback, isFalse);
      expect(controller.isPlaying, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      expect(controller.currentImage.width, 20);
      controller.dispose();
    });

    testWidgets('ignores playback commands', (tester) async {
      final controller = await loadFixture(tester)
        ..play()
        ..togglePlay()
        ..stepForward()
        ..stepBackward()
        ..seek(5);

      expect(controller.isPlaying, isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      expect(controller.frameIndex.value, 0);
      controller.dispose();
    });

    testWidgets('disposes the frame exactly once', (tester) async {
      final controller = await loadFixture(tester);
      final image = controller.currentImage;

      controller.dispose();

      expect(image.debugDisposed, isTrue);
    });
  });

  testWidgets('exposes the failure when loading fails', (tester) async {
    stubLoad(const Err(NoConnectionFailure()));
    final controller = GifStudioController(vsync: tester, loader: loader);

    await controller.load(url: 'https://media.giphy.com/media/abc/giphy.gif');

    expect(controller.status, StudioStatus.failure);
    expect(controller.failure, const NoConnectionFailure());
    controller.dispose();
  });

  testWidgets('pauses in the background and resumes in the foreground', (
    tester,
  ) async {
    final controller = await loadedController(tester, frames: 3);

    void moveTo(List<AppLifecycleState> states) =>
        states.forEach(tester.binding.handleAppLifecycleStateChanged);

    moveTo(const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(controller.isPlaying, isFalse);

    moveTo(const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    expect(controller.isPlaying, isTrue);
    controller.dispose();
  });

  testWidgets('disposes every decoded frame', (tester) async {
    final frames = await decodeFrames(tester, 2);
    stubLoad(Success(frames));
    final controller = GifStudioController(vsync: tester, loader: loader);
    await controller.load(url: 'https://media.giphy.com/media/abc/giphy.gif');

    controller.dispose();

    expect(
      frames.map((frame) => frame.image.debugDisposed),
      everyElement(isTrue),
    );
  });

  testWidgets('disposes frames that arrive after the controller is gone', (
    tester,
  ) async {
    final frames = await decodeFrames(tester, 2);
    final images = <ui.Image>[for (final frame in frames) frame.image];
    when(
      () => loader.load(
        url: any(named: 'url'),
        file: any(named: 'file'),
        cancellation: any(named: 'cancellation'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => Success(frames));
    final controller = GifStudioController(vsync: tester, loader: loader);

    final loading = controller.load(
      url: 'https://media.giphy.com/media/a/g.gif',
    );
    controller.dispose();
    await loading;

    expect(images.map((image) => image.debugDisposed), everyElement(isTrue));
  });
}
