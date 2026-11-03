class RemixDraft {
  const new({
    required this.sourceGifId,
    required this.sourceTitle,
    required this.width,
    required this.height,
    required this.frameCount,
    required this.duration,
  });

  final String sourceGifId;
  final String sourceTitle;
  final int width;
  final int height;
  final int frameCount;
  final Duration duration;
}
