import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/app.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/details/gif_details_page.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:gif_loop/features/remix/remix_editor_page.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:gif_loop/features/search/data/recent_searches_repository.dart';
import 'package:gif_loop/features/search/widgets/search_panel_row.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/gif_factory.dart';
import '../helpers/mocks.dart';
import '../helpers/preferences.dart';
import '../helpers/pump_app.dart';

// The editor preview animates continuously, so pumpAndSettle would never
// return; pumping past route and dialog transitions is enough.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  late GetIt getIt;
  late GoRouterCoordinator coordinator;
  late MockGifRepository repository;
  late MockLibraryRepository library;
  late MockGifFrameLoader frameLoader;
  late List<MethodCall> exits;

  final gifs = makeGifs([1, 2, 3, 4, 5, 6]);

  setUpAll(registerTestFallbacks);

  setUp(() {
    repository = MockGifRepository();
    library = MockLibraryRepository();
    frameLoader = MockGifFrameLoader();
    final colorExtractor = MockDominantColorExtractor();
    when(
      () => repository.trending(
        offset: any(named: 'offset'),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer((_) async => Success(makePage(gifs, totalCount: 6)));
    when(
      () => repository.search(
        any(),
        offset: any(named: 'offset'),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer((_) async => Success(makePage(gifs, totalCount: 6)));
    when(repository.trendingSearches)
        .thenAnswer((_) async => const Success(['party', 'coffee']));
    when(
      () => repository.searchSuggestions(
        any(),
        limit: any(named: 'limit'),
        cancellation: any(named: 'cancellation'),
      ),
    ).thenAnswer((_) async => const Success(['cat', 'cat dance']));
    when(library.favorites).thenAnswer((_) async => const []);
    when(library.remixes).thenAnswer((_) async => const []);
    when(() => library.favorite(any())).thenAnswer((_) async => null);
    when(
      () => colorExtractor.extract(any(), localFile: any(named: 'localFile')),
    ).thenAnswer((_) async => null);

    getIt = GetIt.asNewInstance()
      ..registerFactory(
        () => FeedBloc(repository: repository, debounce: Duration.zero),
      )
      ..registerFactory(
        () => SuggestionsCubit(repository: repository, debounce: Duration.zero),
      )
      ..registerFactory(
        () => RecentSearchesCubit(
          RecentSearchesRepository(inMemoryPreferences()),
        ),
      )
      ..registerFactory(() => TrendingSearchesCubit(repository))
      ..registerFactoryParam<GifDetailsCubit, String, Gif?>(
        (gifId, initialGif) => GifDetailsCubit(
          gifId: gifId,
          initialGif: initialGif,
          repository: repository,
          colorExtractor: colorExtractor,
          libraryRepository: library,
        ),
      )
      ..registerFactoryParam<RemixEditorCubit, Gif, StudioSettings>(
        (gif, initialSettings) => RemixEditorCubit(
          gif: gif,
          initialSettings: initialSettings,
          frameLoader: frameLoader,
          exporter: const RemixExporter(),
          libraryRepository: library,
        ),
      );
    coordinator = GoRouterCoordinator(getIt);

    exits = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') exits.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    coordinator.router.dispose();
  });

  Future<void> stubFrames(WidgetTester tester) async {
    final image = await tester.runAsync(() => createTestImage(cache: false));
    final frames = [
      for (var i = 0; i < 4; i++)
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

  Future<void> pumpRealApp(WidgetTester tester) async {
    tester.view
      ..physicalSize = TestScreen.phonePortrait.size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final connectivity = MockConnectivityCubit();
    when(() => connectivity.state).thenReturn(ConnectivityStatus.online);
    final favorites = FavoritesCubit(library);
    final remixes = RemixesCubit(library);
    await favorites.load();
    await remixes.load();
    await tester.pumpWidget(
      GifLoopApp(
        coordinator: coordinator,
        connectivityCubit: connectivity,
        favoritesCubit: favorites,
        remixesCubit: remixes,
        frameLoader: frameLoader,
      ),
    );
    await _settle(tester);
  }

  Future<void> systemBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await _settle(tester);
  }

  String searchFieldText(WidgetTester tester) =>
      tester.widget<SearchBar>(find.byType(SearchBar)).controller?.text ?? '';

  group('system back on Explore', () {
    testWidgets('closes the search panel and unfocuses the field first', (
      tester,
    ) async {
      await pumpRealApp(tester);
      await tester.tap(find.byType(SearchBar));
      await tester.enterText(find.byType(SearchBar), 'ca');
      await _settle(tester);
      expect(find.byType(SearchPanelRow), findsWidgets);

      await systemBack(tester);

      expect(find.byType(SearchPanelRow), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<EditableText>()),
      );
      expect(searchFieldText(tester), 'ca');
      expect(exits, isEmpty);
    });

    testWidgets('clears the query, shows Trending and scrolls to the top', (
      tester,
    ) async {
      await pumpRealApp(tester);
      await tester.tap(find.text('coffee'));
      await _settle(tester);
      expect(find.text(Strings.resultsFor('coffee')), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await _settle(tester);

      await systemBack(tester);

      expect(find.text(Strings.trending), findsOneWidget);
      expect(searchFieldText(tester), isEmpty);
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(scrollable.position.pixels, 0);
      expect(exits, isEmpty);
    });

    testWidgets('exits the app when there is nothing to undo', (tester) async {
      await pumpRealApp(tester);

      await systemBack(tester);

      expect(exits, hasLength(1));
    });
  });

  testWidgets('system back on Library switches to Explore', (tester) async {
    await pumpRealApp(tester);
    await tester.tap(find.text(Strings.libraryTab));
    await _settle(tester);
    expect(find.text(Strings.noFavoritesTitle), findsOneWidget);

    await systemBack(tester);

    expect(find.text(Strings.noFavoritesTitle), findsNothing);
    expect(find.text(Strings.trending), findsOneWidget);
    expect(exits, isEmpty);
  });

  testWidgets('system back on the detail page returns to the feed', (
    tester,
  ) async {
    await stubFrames(tester);
    await pumpRealApp(tester);
    coordinator.showGifDetails(gifs.first);
    await _settle(tester);
    expect(find.byType(GifDetailsPage), findsOneWidget);

    await systemBack(tester);

    expect(find.byType(GifDetailsPage), findsNothing);
    expect(find.text(Strings.trending), findsOneWidget);
    expect(exits, isEmpty);
  });

  testWidgets('system back in the remix editor asks to discard changes', (
    tester,
  ) async {
    await stubFrames(tester);
    await pumpRealApp(tester);
    coordinator.showRemixEditor(gifs.first, const StudioSettings());
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump();

    await systemBack(tester);
    expect(find.text(Strings.discardChangesTitle), findsOneWidget);
    expect(find.byType(RemixEditorPage), findsOneWidget);

    await tester.tap(find.text(Strings.discard));
    await _settle(tester);

    expect(find.byType(RemixEditorPage), findsNothing);
    expect(exits, isEmpty);
  });
}
