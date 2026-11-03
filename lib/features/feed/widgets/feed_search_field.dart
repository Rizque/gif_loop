import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/platform/platform.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';

class FeedSearchField extends StatefulWidget {
  const new({super.key});

  @override
  State<FeedSearchField> createState() => _FeedSearchFieldState();
}

class _FeedSearchFieldState extends State<FeedSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) =>
      context.read<FeedBloc>().add(FeedQueryChanged(query));

  void _onSubmitted(String query) =>
      context.read<FeedBloc>().add(FeedQuerySubmitted(query));

  void _clear() {
    _controller.clear();
    _onSubmitted('');
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.l,
      Spacing.s,
      Spacing.l,
      Spacing.xs,
    ),
    child: context.isCupertino
        ? CupertinoSearchTextField(
            controller: _controller,
            placeholder: Strings.searchHint,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            onSuffixTap: _clear,
          )
        : SearchBar(
            controller: _controller,
            hintText: Strings.searchHint,
            elevation: const WidgetStatePropertyAll(0),
            textInputAction: TextInputAction.search,
            leading: const Icon(Icons.search_rounded),
            trailing: [
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _controller.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: Strings.clearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _clear,
                      ),
              ),
            ],
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
          ),
  );
}
