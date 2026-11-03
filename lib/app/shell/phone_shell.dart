import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/app/shell/app_tab_presentation.dart';
import 'package:gif_loop/core/platform/platform.dart';
import 'package:gif_loop/core/theme/spacing.dart';

// Phones always use a bottom bar. It hides while the user scrolls down and
// comes back on scroll up. Scroll events are read from the active tab with
// notifications, so pages don't need to share their scroll controllers.
class PhoneShell extends StatefulWidget {
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
  State<PhoneShell> createState() => _PhoneShellState();
}

class _PhoneShellState extends State<PhoneShell> {
  final Map<AppTab, BuildContext> _scrollContexts = {};
  bool _isHiddenByScroll = false;
  ScrollDirection _userDirection = ScrollDirection.idle;

  @override
  void didUpdateWidget(PhoneShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab != widget.currentTab) {
      _isHiddenByScroll = false;
      _userDirection = ScrollDirection.idle;
    }
  }

  // The direction comes from UserScrollNotification, which fires before the
  // position moves, so it is applied on the scroll updates that follow.
  bool _onScroll(ScrollNotification notification) {
    if (!_isMainScrollable(notification.metrics, notification.depth)) {
      return false;
    }
    if (notification.context case final context?) {
      _scrollContexts[widget.currentTab] = context;
    }
    if (notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle) {
      _userDirection = notification.direction;
    }
    _update(notification.metrics);
    return false;
  }

  bool _onMetricsChanged(ScrollMetricsNotification notification) {
    if (_isMainScrollable(notification.metrics, notification.depth)) {
      _update(notification.metrics);
    }
    return false;
  }

  static bool _isMainScrollable(ScrollMetrics metrics, int depth) =>
      depth == 0 && metrics.axis == Axis.vertical;

  void _update(ScrollMetrics metrics) {
    final isAtTop = metrics.extentBefore <= 0;
    final isScrollable = metrics.maxScrollExtent > metrics.minScrollExtent;
    final hide =
        !isAtTop && isScrollable && _userDirection == ScrollDirection.reverse;
    if (hide != _isHiddenByScroll) setState(() => _isHiddenByScroll = hide);
  }

  void _onTabTapped(int index) {
    final tab = AppTab.values[index];
    if (tab == widget.currentTab) {
      _scrollToTop();
    } else {
      widget.onTabSelected(tab);
    }
  }

  void _scrollToTop() {
    final context = _scrollContexts[widget.currentTab];
    if (context == null || !context.mounted) return;
    final position = Scrollable.maybeOf(context)?.position;
    if (position == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      position.jumpTo(position.minScrollExtent);
    } else {
      position.animateTo(
        position.minScrollExtent,
        duration: AppDurations.medium,
        curve: Easing.standard,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always shown when hiding would get in the way: keyboard open, a dialog
    // or sheet on top, or a screen reader (bars must stay reachable).
    final isVisible =
        !_isHiddenByScroll ||
        MediaQuery.viewInsetsOf(context).bottom > 0 ||
        MediaQuery.accessibleNavigationOf(context) ||
        !(ModalRoute.of(context)?.isCurrent ?? true);
    return Scaffold(
      body: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetricsChanged,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
      ),
      bottomNavigationBar: ClipRect(
        child: AnimatedAlign(
          alignment: Alignment.topCenter,
          heightFactor: isVisible ? 1 : 0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppDurations.short,
          curve: Easing.standard,
          child: _BottomBar(currentTab: widget.currentTab, onTap: _onTabTapped),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const new({required this.currentTab, required this.onTap});

  final AppTab currentTab;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => context.isCupertino
      ? CupertinoTabBar(
          currentIndex: currentTab.index,
          onTap: onTap,
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
          onDestinationSelected: onTap,
          destinations: [
            for (final tab in AppTab.values)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
          ],
        );
}
