import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';
import 'package:gif_loop/features/details/cubit/gif_details_state.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';

class GifDetailsCubit extends Cubit<GifDetailsState> {
  new({
    required this._gifId,
    required this._repository,
    required this._colorExtractor,
    required this._libraryRepository,
    Gif? initialGif,
  }) : super(
         initialGif == null
             ? const GifDetailsState(status: GifDetailsStatus.loading)
             : GifDetailsState(
                 status: GifDetailsStatus.success,
                 gif: initialGif,
               ),
       );

  final String _gifId;
  final GifRepository _repository;
  final DominantColorExtractor _colorExtractor;
  final LibraryRepository _libraryRepository;

  Future<void> load() async {
    final favorite = await _libraryRepository.favorite(_gifId);
    if (isClosed) return;
    final known = state.gif ?? favorite?.gif;
    if (known != null) {
      if (state.gif == null) {
        emit(GifDetailsState(status: GifDetailsStatus.success, gif: known));
      }
      await _extractColor(known, localPreview: favorite?.previewFile);
      return;
    }
    emit(const GifDetailsState(status: GifDetailsStatus.loading));
    final result = await _repository.gifById(_gifId);
    if (isClosed) return;
    switch (result) {
      case Success(value: final gif):
        emit(GifDetailsState(status: GifDetailsStatus.success, gif: gif));
        await _extractColor(gif);
      case Err(:final failure):
        emit(
          GifDetailsState(status: GifDetailsStatus.failure, failure: failure),
        );
    }
  }

  Future<void> reconnected() async {
    if (state.status == GifDetailsStatus.failure &&
        (state.failure?.isTransient ?? false)) {
      await load();
    }
  }

  Future<void> _extractColor(Gif gif, {File? localPreview}) async {
    final color = await _colorExtractor.extract(
      gif.preview.url,
      localFile: localPreview,
    );
    if (isClosed || color == null) return;
    emit(
      GifDetailsState(
        status: GifDetailsStatus.success,
        gif: gif,
        dominantColor: color,
      ),
    );
  }
}
