import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/remix/remix_viewer_page.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockLibraryRepository library;
  late MockGifFrameLoader frameLoader;
  late MockAppCoordinator coordinator;
  late RemixesCubit remixes;

  final remix = Remix(
    id: '42',
    sourceGifId: 'abc',
    sourceTitle: 'Dancing cat',
    file: File('remixes/42.gif'),
    width: 480,
    height: 270,
    frameCount: 24,
    duration: const Duration(milliseconds: 2400),
    sizeBytes: 2048,
    createdAt: DateTime(2026, 11, 3),
  );

  setUpAll(registerTestFallbacks);

  setUp(() {
    library = MockLibraryRepository();
    frameLoader = MockGifFrameLoader();
    coordinator = MockAppCoordinator();
    remixes = RemixesCubit(library)..added(remix);
    when(() => library.deleteRemix(any())).thenAnswer((_) async {});
  });

  Future<void> pumpViewer(
    WidgetTester tester, {
    String remixId = '42',
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    bool disableAnimations = false,
  }) async {
    final image = await tester.runAsync(() => createTestImage(cache: false));
    final frames = [
      for (var i = 0; i < 3; i++)
        GifFrame(image!.clone(), const Duration(milliseconds: 100)),
    ];
    image!.dispose();
    when(
      () => frameLoader.load(
        url: any(named: 'url'),
        file: any(named: 'file'),
        cancellation: any(named: 'cancellation'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((invocation) async {
      (invocation.namedArguments[#onProgress] as ValueChanged<double>)(1);
      return Success(frames);
    });
    await tester.pumpApp(
      BlocProvider.value(
        value: remixes,
        child: RemixViewerPage(remixId: remixId),
      ),
      coordinator: coordinator,
      repositories: [
        RepositoryProvider<GifFrameLoader>.value(value: frameLoader),
      ],
      screen: screen,
      textScale: textScale,
      themeMode: themeMode,
      disableAnimations: disableAnimations,
    );
    await tester.pump();
  }

  testWidgets('plays the local file and shows its info', (tester) async {
    await pumpViewer(tester);

    verify(
      () => frameLoader.load(
        url: any(named: 'url'),
        file: remix.file,
        cancellation: any(named: 'cancellation'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(1);
    expect(find.text('480 × 270'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text(Strings.seconds('2.4')), findsOneWidget);
    expect(find.text('Dancing cat'), findsOneWidget);
    expect(find.text(Strings.share), findsOneWidget);
    expect(find.text(Strings.delete), findsOneWidget);
  });

  testWidgets('opens the source GIF from "Remixed from"', (tester) async {
    await pumpViewer(tester);

    await tester.ensureVisible(find.text('Dancing cat'));
    await tester.tap(find.text('Dancing cat'));

    verify(() => coordinator.showGifDetailsById('abc')).called(1);
  });

  testWidgets('deletes after confirmation', (tester) async {
    await pumpViewer(tester);

    await tester.ensureVisible(find.text(Strings.delete));
    await tester.tap(find.text(Strings.delete));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Strings.deleteRemixTitle), findsOneWidget);

    await tester.tap(find.text(Strings.delete).last);
    await tester.pump();

    verify(coordinator.back).called(1);
    verify(() => library.deleteRemix('42')).called(1);
    expect(remixes.state.remixes, isEmpty);
  });

  testWidgets('starts paused when animations are off', (tester) async {
    await pumpViewer(tester, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byTooltip(Strings.play), findsOneWidget);
    expect(find.text(Strings.frameCounter(1, 3)), findsOneWidget);
  });

  testWidgets('loops when animations are on', (tester) async {
    await pumpViewer(tester);

    expect(find.byTooltip(Strings.pause), findsOneWidget);
  });

  testWidgets('shows a message for an unknown remix', (tester) async {
    await pumpViewer(tester, remixId: 'missing');

    expect(find.text(Strings.remixNotFoundTitle), findsOneWidget);
  });

  testWidgets('meets the tap target guideline', (tester) async {
    await pumpViewer(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  group('layout', () {
    for (final screen in TestScreen.values) {
      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'fits ${screen.name} in ${themeMode.name} at 1.5x text scale',
          (tester) async {
            await pumpViewer(
              tester,
              screen: screen,
              textScale: 1.5,
              themeMode: themeMode,
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
