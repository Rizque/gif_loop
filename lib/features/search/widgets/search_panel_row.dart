import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/platform.dart';

class SearchPanelRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.trailing,
  });

  static const double _minHeight = 48;

  final IconData icon;
  final Widget title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    if (!context.isCupertino) {
      return ListTile(
        leading: Icon(icon),
        title: title,
        trailing: trailing,
        onTap: onTap,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.systemGrey),
        title: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodyLarge,
          child: title,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
