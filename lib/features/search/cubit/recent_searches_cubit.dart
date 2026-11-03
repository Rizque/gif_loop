import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/features/search/data/recent_searches_repository.dart';

// Recent searches are a convenience: if storage fails, the list simply stays
// as it was instead of surfacing an error.
class RecentSearchesCubit extends Cubit<List<String>> {
  new(this._repository) : super(const []);

  final RecentSearchesRepository _repository;

  Future<void> load() => _update(_repository.load);

  Future<void> add(String query) => _update(() => _repository.add(query));

  Future<void> remove(String query) => _update(() => _repository.remove(query));

  Future<void> clear() => _update(_repository.clear);

  Future<void> _update(Future<List<String>> Function() change) async {
    try {
      final entries = await change();
      if (!isClosed) emit(entries);
    } on Exception {
      return;
    }
  }
}
