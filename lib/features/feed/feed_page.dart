import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/config/breakpoints.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/widgets/size_reporter.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/feed/widgets/feed_search_field.dart';
import 'package:gif_loop/features/feed/widgets/feed_view.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/widgets/search_panel.dart';

class FeedPage extends StatefulWidget {
  const new({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<double> _headerHeight = ValueNotifier(0);

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _headerHeight.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    context.read<FeedBloc>().add(FeedQueryChanged(text));
    context.read<SuggestionsCubit>().queryChanged(text);
  }

  void _runSearch(String query) {
    final trimmed = query.trim();
    _controller.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _focusNode.unfocus();
    context.read<SuggestionsCubit>().clear();
    context.read<FeedBloc>().add(FeedQuerySubmitted(trimmed));
    if (trimmed.isNotEmpty) {
      unawaited(context.read<RecentSearchesCubit>().add(trimmed));
    }
  }

  void _clear() => _runSearch('');

  // Android back steps out of search before leaving the app: first it
  // closes the search panel, then it clears the query (back to Trending).
  void _onBackPressed() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      context.read<SuggestionsCubit>().clear();
      return;
    }
    _clear();
  }

  @override
  Widget build(BuildContext context) {
    final searchField = FeedSearchField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onChanged,
      onSubmitted: _runSearch,
      onCleared: _clear,
    );
    final searchPanel = SearchPanel(
      focusNode: _focusNode,
      controller: _controller,
      onSearch: _runSearch,
    );
    // On a landscape phone vertical space is scarce, so the search field
    // floats with the grid: it scrolls away and returns on a small scroll up.
    final body = Breakpoints.isPhoneLandscape(MediaQuery.sizeOf(context))
        ? Stack(
            children: [
              FeedView(
                onSearch: _runSearch,
                floatingHeader: SizeReporter(
                  onSizeChanged: (size) {
                    if (mounted) _headerHeight.value = size.height;
                  },
                  child: searchField,
                ),
              ),
              Positioned.fill(
                child: ValueListenableBuilder<double>(
                  valueListenable: _headerHeight,
                  builder: (context, headerHeight, panel) => Padding(
                    padding: EdgeInsets.only(top: headerHeight),
                    child: panel,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: searchPanel,
                  ),
                ),
              ),
            ],
          )
        : Column(
            children: [
              searchField,
              Expanded(
                child: Stack(
                  children: [
                    FeedView(onSearch: _runSearch),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: searchPanel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
    final scaffold = Scaffold(body: SafeArea(bottom: false, child: body));
    return ReconnectListener(
      onReconnected: () =>
          context.read<FeedBloc>().add(const FeedReconnected()),
      child: BlocSelector<FeedBloc, FeedState, bool>(
        selector: (state) => state.query.isNotEmpty,
        builder: (context, hasQuery) => ListenableBuilder(
          listenable: Listenable.merge([_focusNode, _controller]),
          builder: (context, child) => PopScope(
            canPop:
                !hasQuery &&
                !_focusNode.hasFocus &&
                _controller.text.trim().isEmpty,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _onBackPressed();
            },
            child: child ?? const SizedBox.shrink(),
          ),
          child: scaffold,
        ),
      ),
    );
  }
}
