import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

enum FeedStatus { initial, loading, success, failure }

enum LoadMoreStatus { idle, loading, failure }

class FeedState extends Equatable {
  const new({
    this.query = '',
    this.items = const [],
    this.status = FeedStatus.initial,
    this.loadMore = LoadMoreStatus.idle,
    this.hasReachedEnd = false,
    this.nextOffset = 0,
    this.failure,
    this.loadMoreFailure,
  });

  final String query;
  final List<Gif> items;
  final FeedStatus status;
  final LoadMoreStatus loadMore;
  final bool hasReachedEnd;
  final int nextOffset;
  final Failure? failure;
  final Failure? loadMoreFailure;

  bool get canLoadMore =>
      items.isNotEmpty &&
      status != FeedStatus.loading &&
      loadMore == LoadMoreStatus.idle &&
      !hasReachedEnd;

  FeedState copyWith({
    List<Gif>? items,
    FeedStatus? status,
    LoadMoreStatus? loadMore,
    bool? hasReachedEnd,
    int? nextOffset,
    ValueGetter<Failure?>? failure,
    ValueGetter<Failure?>? loadMoreFailure,
  }) => FeedState(
    query: query,
    items: items ?? this.items,
    status: status ?? this.status,
    loadMore: loadMore ?? this.loadMore,
    hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    nextOffset: nextOffset ?? this.nextOffset,
    failure: failure == null ? this.failure : failure(),
    loadMoreFailure: loadMoreFailure == null
        ? this.loadMoreFailure
        : loadMoreFailure(),
  );

  @override
  List<Object?> get props => [
    query,
    items,
    status,
    loadMore,
    hasReachedEnd,
    nextOffset,
    failure,
    loadMoreFailure,
  ];
}
