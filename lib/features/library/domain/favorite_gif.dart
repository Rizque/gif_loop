import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class FavoriteGif extends Equatable {
  const new({
    required this.gif,
    required this.previewFile,
    required this.fullFile,
    required this.addedAt,
  });

  final Gif gif;
  final File previewFile;
  final File fullFile;
  final DateTime addedAt;

  @override
  List<Object?> get props => [gif, previewFile.path, fullFile.path, addedAt];
}
