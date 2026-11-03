sealed class FeedEvent {
  const new();
}

final class FeedStarted extends FeedEvent {
  const new();
}

sealed class FeedQueryEvent extends FeedEvent {
  const new(this.query);

  final String query;
}

final class FeedQueryChanged extends FeedQueryEvent {
  const new(super.query);
}

final class FeedQuerySubmitted extends FeedQueryEvent {
  const new(super.query);
}

final class FeedNextPageRequested extends FeedEvent {
  const new();
}

final class FeedLoadMoreRetried extends FeedEvent {
  const new();
}

final class FeedRefreshed extends FeedEvent {
  const new();
}

final class FeedRetried extends FeedEvent {
  const new();
}

final class FeedReconnected extends FeedEvent {
  const new();
}
