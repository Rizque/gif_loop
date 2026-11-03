import 'package:flutter/material.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/app/shell/phone_shell.dart';
import 'package:gif_loop/app/shell/tablet_shell.dart';
import 'package:gif_loop/core/config/breakpoints.dart';

class AppShell extends StatelessWidget {
  const new({
    required this.currentTab,
    required this.onTabSelected,
    required this.child,
    super.key,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final Widget child;

  // go_router sends system back to the active branch navigator first and
  // then to the root navigator, where this shell route lives: so a pop that
  // the Explore page did not handle ends up here.
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: currentTab == AppTab.explore,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onTabSelected(AppTab.explore);
    },
    child: Breakpoints.isTablet(MediaQuery.sizeOf(context))
        ? TabletShell(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
            child: child,
          )
        : PhoneShell(
            currentTab: currentTab,
            onTabSelected: onTabSelected,
            child: child,
          ),
  );
}
