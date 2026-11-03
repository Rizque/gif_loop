import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/features/library/cubit/remixes_state.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:gif_loop/features/library/domain/remix.dart';

class RemixesCubit extends Cubit<RemixesState> {
  new(this._repository) : super(const RemixesState());

  final LibraryRepository _repository;

  Future<void> load() async {
    final remixes = await _repository.remixes();
    if (!isClosed) emit(RemixesState(remixes: remixes, isLoaded: true));
  }

  void added(Remix remix) =>
      emit(RemixesState(remixes: [remix, ...state.remixes], isLoaded: true));

  Future<void> delete(Remix remix) async {
    emit(
      RemixesState(
        remixes: [
          for (final existing in state.remixes)
            if (existing.id != remix.id) existing,
        ],
        isLoaded: state.isLoaded,
      ),
    );
    await _repository.deleteRemix(remix.id);
  }
}
