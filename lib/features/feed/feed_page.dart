import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
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
    final scaffold = Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FeedSearchField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _runSearch,
              onCleared: _clear,
            ),
            Expanded(
              child: Stack(
                children: [
                  FeedView(onSearch: _runSearch),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SearchPanel(
                        focusNode: _focusNode,
                        controller: _controller,
                        onSearch: _runSearch,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
