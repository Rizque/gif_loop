import 'package:equatable/equatable.dart';

class GifRendition extends Equatable {
  const new({
    required this.url,
    required this.width,
    required this.height,
    this.sizeBytes,
    this.frameCount,
  });

  final String url;
  final int width;
  final int height;
  final int? sizeBytes;
  final int? frameCount;

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;

  @override
  List<Object?> get props => [url, width, height, sizeBytes, frameCount];
}
