import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/core/strings.dart';

extension AppTabPresentation on AppTab {
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
