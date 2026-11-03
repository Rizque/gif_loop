import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class GifPage extends Equatable {
  const new({
    required this.items,
    required this.offset,
    required this.count,
    required this.totalCount,
    required this.maxOffset,
  });

  final List<Gif> items;
  final int offset;
  final int count;
  final int totalCount;
  final int maxOffset;

  int get nextOffset => offset + count;

  bool get hasMore =>
      count > 0 && nextOffset < totalCount && nextOffset <= maxOffset;

  @override
  List<Object?> get props => [items, offset, count, totalCount, maxOffset];
}
