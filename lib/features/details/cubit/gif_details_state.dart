import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

enum GifDetailsStatus { loading, success, failure }

class GifDetailsState extends Equatable {
  const new({required this.status, this.gif, this.failure, this.dominantColor});

  final GifDetailsStatus status;
  final Gif? gif;
  final Failure? failure;
  final Color? dominantColor;

  @override
  List<Object?> get props => [status, gif, failure, dominantColor];
}
