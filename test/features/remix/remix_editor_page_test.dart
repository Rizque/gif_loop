import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:gif_loop/features/remix/remix_editor_page.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

// The live preview animates continuously, so pumpAndSettle would never
// return; pumping past the route and dialog transitions is enough.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  late MockGifFrameLoader frameLoader;
  late MockLibraryRepository library;
  late MockAppCoordinator coordinator;

  final gif = makeGif('abc');

  setUpAll(registerTestFallbacks);

  setUp(() {
    frameLoader = MockGifFrameLoader();
    library = MockLibraryRepository();
    coordinator = MockAppCoordinator();
  });

  Future<void> stubFrames(WidgetTester tester, int count) async {
    final image = await tester.runAsync(() => createTestImage(cache: false));
    final frames = [
      for (var i = 0; i < count; i++)
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
  }

  Future<void> pumpEditor(
    WidgetTester tester, {
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final editor = RemixEditorCubit(
      gif: gif,
      initialSettings: const StudioSettings(),
      frameLoader: frameLoader,
      exporter: const RemixExporter(),
      libraryRepository: library,
    );
    final favorites = FavoritesCubit(library);
    final remixes = RemixesCubit(library);
    await tester.pumpApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: favorites),
                      BlocProvider.value(value: remixes),
                      BlocProvider.value(value: editor),
                    ],
                    child: RemixEditorPage(gif: gif),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      coordinator: coordinator,
      repositories: [
        RepositoryProvider<GifFrameLoader>.value(value: frameLoader),
      ],
      screen: screen,
      textScale: textScale,
      themeMode: themeMode,
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('shows the output size, frame count and duration', (
    tester,
  ) async {
    await stubFrames(tester, 12);

    await pumpEditor(tester);

    expect(find.text(Strings.remixInfo(480, 360, 12, '1.2')), findsOneWidget);
    expect(find.text(Strings.trimRange(1, 12)), findsOneWidget);
    expect(find.text(Strings.topText), findsOneWidget);
    expect(find.text(Strings.bottomText), findsOneWidget);
  });

  testWidgets('disables export above the frame cap', (tester) async {
    await stubFrames(tester, RemixLimits.maxOutputFrames + 1);

    await pumpEditor(tester);
    await tester.scrollUntilVisible(
      find.text(Strings.frameLimitExceeded),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );

    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(Strings.exportGif),
        matching: find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        ),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('asks before discarding changes on back', (tester) async {
    await stubFrames(tester, 6);
    await pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump();
    await tester.pageBack();
    await settle(tester);

    expect(find.text(Strings.discardChangesTitle), findsOneWidget);

    await tester.tap(find.text(Strings.keepEditing));
    await settle(tester);
    expect(find.byType(RemixEditorPage), findsOneWidget);
    verifyNever(coordinator.back);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.text(Strings.discard));
    await settle(tester);
    verify(coordinator.back).called(1);
  });

  testWidgets('leaves without asking when nothing changed', (tester) async {
    await stubFrames(tester, 6);
    await pumpEditor(tester);

    await tester.pageBack();
    await settle(tester);

    expect(find.byType(RemixEditorPage), findsNothing);
  });

  testWidgets('meets the tap target guideline', (tester) async {
    await stubFrames(tester, 6);
    await pumpEditor(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  group('layout', () {
    for (final screen in TestScreen.values) {
      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets(
          'fits ${screen.name} in ${themeMode.name} at 1.5x text scale',
          (tester) async {
            await stubFrames(tester, 6);

            await pumpEditor(
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

    testWidgets('keeps working with the keyboard open', (tester) async {
      await stubFrames(tester, 6);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);

      await pumpEditor(tester, screen: TestScreen.phoneLandscape);
      await tester.showKeyboard(find.byType(TextField).first);
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
