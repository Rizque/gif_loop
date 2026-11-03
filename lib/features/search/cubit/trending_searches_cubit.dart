import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';

class TrendingSearchesCubit extends Cubit<List<String>> {
  new(this._repository) : super(const []);

  static const int maxTerms = 10;

  final GifRepository _repository;

  // A failure leaves the row hidden; the feed owns the error UI.
  Future<void> load() async {
    final result = await _repository.trendingSearches();
    if (isClosed) return;
    if (result case Success(value: final terms)) {
      emit(terms.take(maxTerms).toList());
    }
  }
}
