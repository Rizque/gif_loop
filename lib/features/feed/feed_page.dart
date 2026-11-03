import 'package:flutter/material.dart';
import 'package:gif_loop/features/feed/widgets/feed_search_field.dart';
import 'package:gif_loop/features/feed/widgets/feed_view.dart';

class FeedPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          FeedSearchField(),
          Expanded(child: FeedView()),
        ],
      ),
    ),
  );
}
