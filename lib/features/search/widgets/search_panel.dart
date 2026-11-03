import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/platform/platform.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/widgets/highlighted_term.dart';
import 'package:gif_loop/features/search/widgets/search_panel_row.dart';

class SearchPanel extends StatelessWidget {
  const new({
    required this.focusNode,
    required this.controller,
    required this.onSearch,
    super.key,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([focusNode, controller]),
    builder: (context, _) {
      if (!focusNode.hasFocus) return const SizedBox.shrink();
      return controller.text.trim().isEmpty
          ? _RecentSearches(onSearch: onSearch)
          : _Suggestions(onSearch: onSearch);
    },
  );
}

class _RecentSearches extends StatelessWidget {
  const new({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final recents = context.watch<RecentSearchesCubit>();
    final entries = recents.state;
    if (entries.isEmpty) return const SizedBox.shrink();
    return _PanelSurface(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: Spacing.l, right: Spacing.s),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Strings.recentSearches,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: recents.clear,
                child: const Text(Strings.clearAll),
              ),
            ],
          ),
        ),
        for (final entry in entries)
          SearchPanelRow(
            icon: Icons.history_rounded,
            title: Text(entry),
            onTap: () => onSearch(entry),
            trailing: IconButton(
              tooltip: Strings.removeRecentSearch(entry),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => recents.remove(entry),
            ),
          ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const new({required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<ConnectivityCubit, bool>(
      (cubit) => cubit.state == ConnectivityStatus.online,
    );
    final state = context.watch<SuggestionsCubit>().state;
    if (!isOnline || state.suggestions.isEmpty) return const SizedBox.shrink();
    return _PanelSurface(
      children: [
        for (final suggestion in state.suggestions)
          SearchPanelRow(
            icon: Icons.search_rounded,
            title: HighlightedTerm(term: suggestion, prefix: state.query),
            onTap: () => onSearch(suggestion),
          ),
      ],
    );
  }
}

class _PanelSurface extends StatelessWidget {
  const new({required this.children});

  static const double _elevation = 3;
  static const double _separatorIndent = 56;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isCupertino = context.isCupertino;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.l),
      child: Material(
        elevation: isCupertino ? 0 : _elevation,
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(Radii.tile),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
          separatorBuilder: (context, index) => isCupertino
              ? const Divider(height: 1, indent: _separatorIndent)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
