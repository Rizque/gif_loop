import 'package:flutter/material.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/app/shell/app_tab_presentation.dart';
import 'package:gif_loop/core/config/breakpoints.dart';

class TabletShell extends StatelessWidget {
  const new({
    required this.currentTab,
    required this.onTabSelected,
    required this.child,
    super.key,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(
      children: [
        SafeArea(
          right: false,
          child: NavigationRail(
            selectedIndex: currentTab.index,
            onDestinationSelected: (index) =>
                onTabSelected(AppTab.values[index]),
            labelType: NavigationRailLabelType.selected,
            minWidth: Breakpoints.railMinWidth,
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
