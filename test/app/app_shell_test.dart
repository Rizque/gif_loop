import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/app/shell/app_shell.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/core/strings.dart';

import '../helpers/pump_app.dart';

void main() {
  late AppTab currentTab;
  late List<AppTab> selectedTabs;

  setUp(() {
    currentTab = AppTab.explore;
    selectedTabs = [];
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    TestScreen screen = TestScreen.modernPhonePortrait,
    bool accessibleNavigation = false,
    bool disableAnimations = false,
  }) => tester.pumpApp(
    StatefulBuilder(
      builder: (context, setState) => AppShell(
        currentTab: currentTab,
        onTabSelected: (tab) {
          selectedTabs.add(tab);
          setState(() => currentTab = tab);
        },
        child: ListView.builder(
          itemCount: 60,
          itemBuilder: (context, index) =>
              SizedBox(height: 80, child: Text('item $index')),
        ),
      ),
    ),
    screen: screen,
    accessibleNavigation: accessibleNavigation,
    disableAnimations: disableAnimations,
  );

  bool isBarVisible(WidgetTester tester) =>
      tester
          .widget<AnimatedAlign>(
            find.ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(AnimatedAlign),
            ),
          )
          .heightFactor ==
      1;

  Future<void> scrollBy(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(ListView), Offset(0, -dy));
    await tester.pumpAndSettle();
  }

  double scrollOffset(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

  group('adaptive navigation', () {
    for (final screen in [
      TestScreen.modernPhonePortrait,
      TestScreen.modernPhoneLandscape,
      TestScreen.phoneLandscape,
    ]) {
      testWidgets('uses a bottom bar and no rail on ${screen.name}', (
        tester,
      ) async {
        await pumpShell(tester, screen: screen);

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
      });
    }

    for (final screen in [
      TestScreen.tabletPortrait,
      TestScreen.tabletLandscape,
    ]) {
      testWidgets('uses a compact rail on ${screen.name}', (tester) async {
        await pumpShell(tester, screen: screen);

        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.labelType, NavigationRailLabelType.selected);
        expect(find.byType(NavigationBar), findsNothing);
      });
    }

    testWidgets(
      'uses a CupertinoTabBar on iOS phones',
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      (tester) async {
        await pumpShell(tester);

        expect(find.byType(CupertinoTabBar), findsOneWidget);
      },
    );

    testWidgets('switches tabs through the callback', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text(Strings.libraryTab));

      expect(selectedTabs, [AppTab.library]);
    });
  });

  group('hide on scroll', () {
    testWidgets('hides when scrolling down and gives the space to content', (
      tester,
    ) async {
      await pumpShell(tester);
      final screenHeight = TestScreen.modernPhonePortrait.size.height;
      expect(
        tester.getBottomLeft(find.byType(ListView)).dy,
        lessThan(screenHeight),
      );

      await scrollBy(tester, 400);

      expect(isBarVisible(tester), isFalse);
      expect(tester.getBottomLeft(find.byType(ListView)).dy, screenHeight);
    });

    testWidgets('comes back when scrolling up', (tester) async {
      await pumpShell(tester);
      await scrollBy(tester, 800);

      await scrollBy(tester, -100);

      expect(isBarVisible(tester), isTrue);
      expect(scrollOffset(tester), greaterThan(0));
    });

    testWidgets('is visible again at the top', (tester) async {
      await pumpShell(tester);
      await scrollBy(tester, 400);

      await tester.fling(find.byType(ListView), const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();

      expect(scrollOffset(tester), 0);
      expect(isBarVisible(tester), isTrue);
    });

    testWidgets('never hides for screen reader users', (tester) async {
      await pumpShell(tester, accessibleNavigation: true);

      await scrollBy(tester, 400);

      expect(isBarVisible(tester), isTrue);
    });

    testWidgets('hides without animation when motion is reduced', (
      tester,
    ) async {
      await pumpShell(tester, disableAnimations: true);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();

      final align = tester.widget<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(align.duration, Duration.zero);
      expect(align.heightFactor, 0);
    });

    testWidgets('does not hide on tablets', (tester) async {
      await pumpShell(tester, screen: TestScreen.tabletPortrait);

      await scrollBy(tester, 400);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(AnimatedAlign), findsNothing);
    });

    testWidgets('tapping the active tab scrolls it to the top', (tester) async {
      await pumpShell(tester);
      await scrollBy(tester, 800);
      await scrollBy(tester, -100);
      expect(isBarVisible(tester), isTrue);

      await tester.tap(find.text(Strings.exploreTab));
      await tester.pumpAndSettle();

      expect(scrollOffset(tester), 0);
      expect(selectedTabs, isEmpty);
    });
  });
}
