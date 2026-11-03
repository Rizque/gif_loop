import 'package:flutter/material.dart';

class HighlightedTerm extends StatelessWidget {
  const new({required this.term, required this.prefix, super.key});

  final String term;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final matches =
        prefix.isNotEmpty &&
        term.toLowerCase().startsWith(prefix.toLowerCase());
    if (!matches) return Text(term);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: term.substring(0, prefix.length),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: term.substring(prefix.length)),
        ],
      ),
    );
  }
}
