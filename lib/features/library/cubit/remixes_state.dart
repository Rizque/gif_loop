import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/library/domain/remix.dart';

class RemixesState extends Equatable {
  const new({this.remixes = const [], this.isLoaded = false});

  final List<Remix> remixes;
  final bool isLoaded;

  Remix? remixOf(String id) {
    for (final remix in remixes) {
      if (remix.id == id) return remix;
    }
    return null;
  }

  @override
  List<Object?> get props => [remixes, isLoaded];
}
