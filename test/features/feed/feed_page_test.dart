import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/feed/feed_page.dart';
import 'package:gif_loop/features/feed/widgets/feed_skeleton.dart';
import 'package:gif_loop/features/feed/widgets/gif_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/pump_app.dart';

class _MockFeedBloc extends MockBloc<FeedEvent, FeedState> implements FeedBloc;

void main() {
  late _MockFeedBloc bloc;
  late MockAppCoordinator coordinator;

  setUpAll(() => registerFallbackValue(const FeedStarted()));

  setUp(() {
    bloc = _MockFeedBloc();
    coordinator = MockAppCoordinator();
  });

  final loaded = FeedState(
    items: makeGifs([1, 2, 3, 4, 5, 6]),
    status: FeedStatus.success,
    nextOffset: 6,
  );

  Future<void> pumpFeed(
    WidgetTester tester, {
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
  }) => tester.pumpApp(
    BlocProvider<FeedBloc>.value(value: bloc, child: const FeedPage()),
    coordinator: coordinator,
    screen: screen,
    textScale: textScale,
  );

  testWidgets('shows the skeleton, then the grid', (tester) async {
    whenListen(
      bloc,
      Stream.value(loaded),
      initialState: const FeedState(status: FeedStatus.loading),
    );

    await pumpFeed(tester);
    expect(find.byType(FeedSkeleton), findsOneWidget);
    expect(find.text(Strings.trending), findsOneWidget);
    expect(find.text(Strings.poweredByGiphy), findsOneWidget);

    await tester.pump();
    expect(find.byType(FeedSkeleton), findsNothing);
    expect(find.byType(GifTile), findsWidgets);
  });

  testWidgets('shows a search header for a query', (tester) async {
    when(() => bloc.state).thenReturn(
      FeedState(query: 'cats', items: loaded.items, status: FeedStatus.success),
    );

    await pumpFeed(tester);

    expect(find.text(Strings.resultsFor('cats')), findsOneWidget);
  });

  testWidgets('opens the details of a tapped GIF', (tester) async {
    when(() => bloc.state).thenReturn(loaded);

    await pumpFeed(tester);
    await tester.tap(find.byType(GifTile).first);

    verify(() => coordinator.showGifDetails(loaded.items.first)).called(1);
  });

  testWidgets('typing in the search field emits query changes', (tester) async {
    when(() => bloc.state).thenReturn(loaded);

    await pumpFeed(tester);
    await tester.enterText(find.byType(SearchBar), 'dogs');

    verify(
      () => bloc.add(
        any(
          that: isA<FeedQueryChanged>().having((e) => e.query, 'query', 'dogs'),
        ),
      ),
    ).called(1);
  });

  testWidgets('shows an error view whose Retry reloads', (tester) async {
    when(() => bloc.state).thenReturn(
      const FeedState(
        status: FeedStatus.failure,
        failure: RateLimitedFailure(),
      ),
    );

    await pumpFeed(tester);
    expect(find.text(const RateLimitedFailure().message), findsOneWidget);

    await tester.tap(find.text(Strings.retry));
    verify(() => bloc.add(any(that: isA<FeedRetried>()))).called(1);
  });

  testWidgets('shows an empty view when a search finds nothing', (
    tester,
  ) async {
    when(() => bloc.state)
        .thenReturn(const FeedState(query: 'zzzz', status: FeedStatus.success));

    await pumpFeed(tester);

    expect(find.text(Strings.noResultsFor('zzzz')), findsOneWidget);
  });

  testWidgets('shows load-more errors inline with Retry', (tester) async {
    when(() => bloc.state).thenReturn(
      loaded.copyWith(
        loadMore: LoadMoreStatus.failure,
        loadMoreFailure: () => const TimeoutFailure(),
      ),
    );

    await pumpFeed(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pump();

    expect(find.byType(GifTile), findsWidgets);
    await tester.tap(find.text(Strings.retry));
    verify(() => bloc.add(any(that: isA<FeedLoadMoreRetried>()))).called(1);
  });

  testWidgets('shows the end of results footer', (tester) async {
    when(() => bloc.state).thenReturn(loaded.copyWith(hasReachedEnd: true));

    await pumpFeed(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pump();

    expect(find.text(Strings.endOfResults), findsOneWidget);
  });

  group('layout', () {
    for (final screen in TestScreen.values) {
      testWidgets('fits ${screen.name} at 1.5x text scale', (tester) async {
        when(() => bloc.state).thenReturn(
          const FeedState(
            status: FeedStatus.failure,
            failure: UnauthorizedFailure(),
          ),
        );

        await pumpFeed(tester, screen: screen, textScale: 1.5);

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('uses more columns in landscape', (tester) async {
      when(() => bloc.state).thenReturn(loaded);

      await pumpFeed(tester, screen: TestScreen.tabletLandscape);

      final firstRowTop = tester.getTopLeft(find.byType(GifTile).first).dy;
      final tilesInFirstRow = find
          .byType(GifTile)
          .evaluate()
          .where(
            (element) =>
                tester.getTopLeft(find.byWidget(element.widget)).dy ==
                firstRowTop,
          );
      expect(tilesInFirstRow.length, greaterThanOrEqualTo(4));
    });
  });
}
