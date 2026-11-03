import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/core/config/breakpoints.dart';
import 'package:gif_loop/core/platform/platform.dart';
import 'package:gif_loop/core/strings.dart';

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
    child: _ShellScaffold(
      currentTab: currentTab,
      onTabSelected: onTabSelected,
      child: child,
    ),
  );
}

class _ShellScaffold extends StatelessWidget {
  const new({
    required this.currentTab,
    required this.onTabSelected,
    required this.child,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final Widget child;

  void _select(int index) => onTabSelected(AppTab.values[index]);

  @override
  Widget build(BuildContext context) {
    final useRail =
        MediaQuery.sizeOf(context).width >= Breakpoints.navigationRail;
    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              right: false,
              child: NavigationRail(
                selectedIndex: currentTab.index,
                onDestinationSelected: _select,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final tab in AppTab.values)
                    NavigationRailDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.selectedIcon),
                      label: Text(tab.label),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                child: child,
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: context.isCupertino
          ? CupertinoTabBar(
              currentIndex: currentTab.index,
              onTap: _select,
              items: [
                for (final tab in AppTab.values)
                  BottomNavigationBarItem(
                    icon: Icon(tab.cupertinoIcon),
                    label: tab.label,
                  ),
              ],
            )
          : NavigationBar(
              selectedIndex: currentTab.index,
              onDestinationSelected: _select,
              destinations: [
                for (final tab in AppTab.values)
                  NavigationDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.selectedIcon),
                    label: tab.label,
                  ),
              ],
            ),
    );
  }
}

extension on AppTab {
  String get label => switch (this) {
    AppTab.explore => Strings.exploreTab,
    AppTab.library => Strings.libraryTab,
  };

  IconData get icon => switch (this) {
    AppTab.explore => Icons.explore_outlined,
    AppTab.library => Icons.video_library_outlined,
  };

  IconData get selectedIcon => switch (this) {
    AppTab.explore => Icons.explore,
    AppTab.library => Icons.video_library,
  };

  IconData get cupertinoIcon => switch (this) {
    AppTab.explore => CupertinoIcons.compass,
    AppTab.library => CupertinoIcons.collections,
  };
}
