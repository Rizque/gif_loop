import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/adaptive_segmented_control.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/library/library_segment.dart';
import 'package:gif_loop/features/library/widgets/favorites_view.dart';
import 'package:gif_loop/features/library/widgets/remixes_view.dart';

class LibraryPage extends StatefulWidget {
  const new({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

// The Library branch stays mounted for the whole session, so the selected
// segment is remembered while the app runs.
class _LibraryPageState extends State<LibraryPage> {
  LibrarySegment _segment = LibrarySegment.favorites;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(Strings.libraryTab)),
    body: SafeArea(
      top: false,
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.l,
              0,
              Spacing.l,
              Spacing.m,
            ),
            child: SizedBox(
              width: double.infinity,
              child: AdaptiveSegmentedControl<LibrarySegment>(
                values: LibrarySegment.values,
                selected: _segment,
                labelOf: (segment) => switch (segment) {
                  LibrarySegment.favorites => Strings.favorites,
                  LibrarySegment.remixes => Strings.myRemixes,
                },
                onChanged: (segment) => setState(() => _segment = segment),
              ),
            ),
          ),
          Expanded(
            child: switch (_segment) {
              LibrarySegment.favorites => const FavoritesView(),
              LibrarySegment.remixes => const RemixesView(),
            },
          ),
        ],
      ),
    ),
  );
}
