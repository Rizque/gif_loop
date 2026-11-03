import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/formatting/byte_size.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/details/cubit/gif_details_state.dart';
import 'package:gif_loop/features/details/gif_details_page.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

class _MockGifDetailsCubit extends MockCubit<GifDetailsState>
    implements GifDetailsCubit;

void main() {
  late _MockGifDetailsCubit cubit;
  late MockGifFrameLoader frameLoader;
  late MockAppCoordinator coordinator;
  late MockLibraryRepository library;
  late FavoritesCubit favorites;

  final gif = makeGif('abc', title: 'Dancing cat');

  setUpAll(registerTestFallbacks);

  setUp(() {
    cubit = _MockGifDetailsCubit();
    frameLoader = MockGifFrameLoader();
    coordinator = MockAppCoordinator();
    when(cubit.load).thenAnswer((_) async {});
    library = MockLibraryRepository();
    favorites = FavoritesCubit(library);
  });

  void stubFrames(Result<List<GifFrame>> result) =>
      when(
        () => frameLoader.load(
          url: any(named: 'url'),
          file: any(named: 'file'),
          cancellation: any(named: 'cancellation'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((invocation) async {
        (invocation.namedArguments[#onProgress] as ValueChanged<double>)(1);
        return result;
      });

  Future<void> stubDecodedFrames(WidgetTester tester, int count) async {
    final frames = <GifFrame>[];
    for (var i = 0; i < count; i++) {
      final image = await tester.runAsync(() => createTestImage(cache: false));
      frames.add(GifFrame(image!, const Duration(milliseconds: 100)));
    }
    stubFrames(Success(frames));
  }

  Future<void> pumpDetails(
    WidgetTester tester,
    GifDetailsState state, {
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
    bool disableAnimations = false,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<GifDetailsCubit>.value(value: cubit),
          BlocProvider<FavoritesCubit>.value(value: favorites),
        ],
        child: const GifDetailsPage(),
      ),
      coordinator: coordinator,
      repositories: [
        RepositoryProvider<GifFrameLoader>.value(value: frameLoader),
      ],
      screen: screen,
      textScale: textScale,
      disableAnimations: disableAnimations,
    );
  }

  GifDetailsState loadedWith(Gif gif) =>
      GifDetailsState(status: GifDetailsStatus.success, gif: gif);

  testWidgets('renders the GIF info and actions', (tester) async {
    await stubDecodedFrames(tester, 3);

    await pumpDetails(tester, loadedWith(gif));
    await tester.pump();

    expect(find.text('Dancing cat'), findsOneWidget);
    expect(find.text('User abc'), findsOneWidget);
    expect(find.text('@user_abc'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('480 × 360'), findsOneWidget);
    expect(find.text(formatByteSize(1536000)), findsOneWidget);
    expect(find.text(Strings.copyLink), findsOneWidget);
    expect(find.text(Strings.share), findsOneWidget);
    expect(find.text(Strings.openInGiphy), findsOneWidget);
    expect(find.text(Strings.poweredByGiphy), findsOneWidget);
  });

  testWidgets('shows Studio controls once frames are decoded', (tester) async {
    await stubDecodedFrames(tester, 3);

    await pumpDetails(tester, loadedWith(gif));
    await tester.pump();

    expect(find.byTooltip(Strings.pause), findsOneWidget);
    expect(find.text(Strings.frameCounter(1, 3)), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.pause));
    await tester.pump();
    expect(find.byTooltip(Strings.play), findsOneWidget);

    await tester.tap(find.byTooltip(Strings.nextFrame));
    await tester.pump();
    expect(find.text(Strings.frameCounter(2, 3)), findsOneWidget);
  });

  group('reduce motion', () {
    testWidgets('starts paused on the first frame when animations are off', (
      tester,
    ) async {
      await stubDecodedFrames(tester, 3);

      await pumpDetails(tester, loadedWith(gif), disableAnimations: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byTooltip(Strings.play), findsOneWidget);
      expect(find.text(Strings.frameCounter(1, 3)), findsOneWidget);
    });

    testWidgets('loops automatically when animations are on', (tester) async {
      await stubDecodedFrames(tester, 3);

      await pumpDetails(tester, loadedWith(gif));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byTooltip(Strings.pause), findsOneWidget);
      expect(find.text(Strings.frameCounter(2, 3)), findsOneWidget);
    });
  });

  testWidgets('hides playback controls for a single-frame image', (
    tester,
  ) async {
    await stubDecodedFrames(tester, 1);

    await pumpDetails(tester, loadedWith(gif));
    await tester.pump();

    expect(find.byTooltip(Strings.play), findsNothing);
    expect(find.byTooltip(Strings.pause), findsNothing);
  });

  testWidgets('shows a Studio error with Retry', (tester) async {
    stubFrames(const Err(DecodingFailure()));

    await pumpDetails(tester, loadedWith(gif));
    await tester.pump();

    await tester.pumpAndSettle();
    expect(find.text(const DecodingFailure().title), findsOneWidget);
    await tester.ensureVisible(find.text(Strings.retry));
    await tester.tap(find.text(Strings.retry));
    await tester.pump();
    verify(
      () => frameLoader.load(
        url: gif.full.url,
        file: any(named: 'file'),
        cancellation: any(named: 'cancellation'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(2);
  });

  testWidgets('shows a loader while fetching by id', (tester) async {
    await pumpDetails(
      tester,
      const GifDetailsState(status: GifDetailsStatus.loading),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error with Retry when fetching by id fails', (
    tester,
  ) async {
    await pumpDetails(
      tester,
      const GifDetailsState(
        status: GifDetailsStatus.failure,
        failure: NotFoundFailure(),
      ),
    );

    await tester.tap(find.text(Strings.retry));
    verify(cubit.load).called(1);
  });

  testWidgets('back goes through the coordinator', (tester) async {
    await pumpDetails(
      tester,
      const GifDetailsState(status: GifDetailsStatus.loading),
    );

    await tester.tap(find.byType(BackButton));
    verify(coordinator.back).called(1);
  });

  testWidgets('meets the tap target guideline', (tester) async {
    await stubDecodedFrames(tester, 3);
    await pumpDetails(tester, loadedWith(gif));
    await tester.pump();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  group('layout', () {
    for (final screen in TestScreen.values) {
      testWidgets('fits ${screen.name} at 1.5x text scale', (tester) async {
        await stubDecodedFrames(tester, 3);

        await pumpDetails(
          tester,
          loadedWith(gif),
          screen: screen,
          textScale: 1.5,
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
