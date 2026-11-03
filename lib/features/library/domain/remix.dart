import 'dart:io';

import 'package:equatable/equatable.dart';

class Remix extends Equatable {
  const new({
    required this.id,
    required this.sourceGifId,
    required this.sourceTitle,
    required this.file,
    required this.width,
    required this.height,
    required this.frameCount,
    required this.duration,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String sourceGifId;
  final String sourceTitle;
  final File file;
  final int width;
  final int height;
  final int frameCount;
  final Duration duration;
  final int sizeBytes;
  final DateTime createdAt;

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1;

  @override
  List<Object?> get props => [
    id,
    sourceGifId,
    sourceTitle,
    file.path,
    width,
    height,
    frameCount,
    duration,
    sizeBytes,
    createdAt,
  ];
}
