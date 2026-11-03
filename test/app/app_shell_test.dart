import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/app/shell/app_shell.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/core/strings.dart';

import '../helpers/pump_app.dart';

void main() {
  Future<AppTab?> pumpShell(
    WidgetTester tester, {
    TestScreen screen = TestScreen.phonePortrait,
    VoidCallback? afterPump,
  }) async {
    AppTab? selected;
    await tester.pumpApp(
      AppShell(
        currentTab: AppTab.explore,
        onTabSelected: (tab) => selected = tab,
        child: const SizedBox.expand(),
      ),
      screen: screen,
    );
    await tester.tap(find.text(Strings.gameTab));
    return selected;
  }

  testWidgets('uses a NavigationBar on narrow Android screens', (tester) async {
    final selected = await pumpShell(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(selected, AppTab.game);
  });

  testWidgets(
    'uses a CupertinoTabBar on narrow iOS screens',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final selected = await pumpShell(tester);

      expect(find.byType(CupertinoTabBar), findsOneWidget);
      expect(selected, AppTab.game);
    },
  );

  testWidgets('uses a NavigationRail on wide screens', (tester) async {
    final selected = await pumpShell(tester, screen: TestScreen.phoneLandscape);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(selected, AppTab.game);
  });
}
