import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/platform.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class FeedSearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;

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
            controller: controller,
            focusNode: focusNode,
            placeholder: Strings.searchHint,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onSuffixTap: onCleared,
          )
        : SearchBar(
            controller: controller,
            focusNode: focusNode,
            hintText: Strings.searchHint,
            elevation: const WidgetStatePropertyAll(0),
            textInputAction: TextInputAction.search,
            leading: const Icon(Icons.search_rounded),
            trailing: [
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => controller.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: Strings.clearSearch,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onCleared,
                      ),
              ),
            ],
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
  );
}
