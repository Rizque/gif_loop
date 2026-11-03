import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/feed/widgets/feed_body.dart';
import 'package:gif_loop/features/feed/widgets/feed_header.dart';

class FeedView extends StatefulWidget {
  const new({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  static const double _loadMoreThreshold = 600;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Also called after layout changes so a first page that does not fill the
  // viewport (e.g. landscape tablet) keeps loading until it does.
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final bloc = context.read<FeedBloc>();
    if (bloc.state.canLoadMore &&
        _scrollController.position.extentAfter < _loadMoreThreshold) {
      bloc.add(const FeedNextPageRequested());
    }
  }

  void _maybeLoadMoreAfterLayout() =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeLoadMore();
      });

  Future<void> _refresh() async {
    final bloc = context.read<FeedBloc>()..add(const FeedRefreshed());
    await bloc.stream.firstWhere((state) => state.status != FeedStatus.loading);
  }

  void _showRefreshFailure(BuildContext context, FeedState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${Strings.refreshFailed} ${state.failure?.message ?? ''}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<FeedBloc, FeedState>(
        listenWhen: (previous, current) => previous.query != current.query,
        listener: (context, state) {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        },
      ),
      BlocListener<FeedBloc, FeedState>(
        listenWhen: (previous, current) =>
            previous.status != FeedStatus.failure &&
            current.status == FeedStatus.failure &&
            current.items.isNotEmpty,
        listener: _showRefreshFailure,
      ),
      BlocListener<FeedBloc, FeedState>(
        listenWhen: (previous, current) => previous.items != current.items,
        listener: (context, state) => _maybeLoadMoreAfterLayout(),
      ),
    ],
    child: NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _maybeLoadMoreAfterLayout();
        return false;
      },
      child: RefreshIndicator.adaptive(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: const [FeedHeader(), FeedBody()],
        ),
      ),
    ),
  );
}
