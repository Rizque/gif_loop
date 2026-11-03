import 'package:flutter/widgets.dart';

// Hidden branches stay mounted to keep their state, but their heroes must
// not take part in transitions started from the visible tab.
class ShellBranchContainer extends StatelessWidget {
  const new({required this.currentIndex, required this.children, super.key});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: currentIndex,
    children: [
      for (final (index, child) in children.indexed)
        HeroMode(
          enabled: index == currentIndex,
          child: TickerMode(enabled: index == currentIndex, child: child),
        ),
    ],
  );
}
