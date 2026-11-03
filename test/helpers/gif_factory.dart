import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';
import 'package:gif_loop/features/gifs/domain/gif_user.dart';

Gif makeGif(String id, {String? title}) => Gif(
  id: id,
  title: title ?? 'GIF $id',
  url: 'https://giphy.com/gifs/$id',
  shareUrl: 'https://gph.is/$id',
  username: 'user_$id',
  user: GifUser(username: 'user_$id', displayName: 'User $id'),
  rating: 'g',
  importDateTime: DateTime(2020, 5, 17),
  preview: GifRendition(
    url: 'https://media.giphy.com/media/$id/200w.webp',
    width: 200,
    height: 150,
  ),
  full: GifRendition(
    url: 'https://media.giphy.com/media/$id/giphy.gif',
    width: 480,
    height: 360,
    sizeBytes: 1536000,
    frameCount: 24,
  ),
);

List<Gif> makeGifs(Iterable<int> ids, {String prefix = 'g'}) => [
  for (final id in ids) makeGif('$prefix$id'),
];

GifPage makePage(
  List<Gif> items, {
  int offset = 0,
  int? count,
  int totalCount = 1000,
  int maxOffset = 4999,
}) => GifPage(
  items: items,
  offset: offset,
  count: count ?? items.length,
  totalCount: totalCount,
  maxOffset: maxOffset,
);
