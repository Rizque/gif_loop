import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/widgets/feed_search_field.dart';
import 'package:gif_loop/features/feed/widgets/feed_view.dart';

class FeedPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ReconnectListener(
    onReconnected: () => context.read<FeedBloc>().add(const FeedReconnected()),
    child: const Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FeedSearchField(),
            Expanded(child: FeedView()),
          ],
        ),
      ),
    ),
  );
}
