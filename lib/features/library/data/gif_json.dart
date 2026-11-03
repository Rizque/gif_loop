import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';
import 'package:gif_loop/features/gifs/domain/gif_user.dart';

Map<String, Object?> gifToJson(Gif gif) => {
  'id': gif.id,
  'title': gif.title,
  'url': gif.url,
  'shareUrl': gif.shareUrl,
  'username': gif.username,
  'rating': gif.rating,
  'importDateTime': gif.importDateTime?.toIso8601String(),
  'user': switch (gif.user) {
    final user? => {
      'username': user.username,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
    },
    null => null,
  },
  'preview': _renditionToJson(gif.preview),
  'full': _renditionToJson(gif.full),
};

Gif? gifFromJson(Map<String, dynamic> json) {
  final id = readString(json['id']);
  final url = readString(json['url']);
  final preview = _renditionFromJson(readMap(json['preview']));
  final full = _renditionFromJson(readMap(json['full']));
  if (id == null || url == null || preview == null || full == null) {
    return null;
  }
  final user = readMap(json['user']);
  final importDate = readString(json['importDateTime']);
  return Gif(
    id: id,
    title: readString(json['title']) ?? '',
    url: url,
    shareUrl: readString(json['shareUrl']) ?? url,
    username: readString(json['username']) ?? '',
    rating: readString(json['rating']) ?? '',
    importDateTime: importDate == null ? null : DateTime.tryParse(importDate),
    user: user == null ? null : _userFromJson(user),
    preview: preview,
    full: full,
  );
}

Map<String, Object?> _renditionToJson(GifRendition rendition) => {
  'url': rendition.url,
  'width': rendition.width,
  'height': rendition.height,
  'sizeBytes': rendition.sizeBytes,
  'frameCount': rendition.frameCount,
};

GifRendition? _renditionFromJson(Map<String, dynamic>? json) {
  final url = readString(json?['url']);
  if (json == null || url == null) return null;
  return GifRendition(
    url: url,
    width: readInt(json['width']) ?? 0,
    height: readInt(json['height']) ?? 0,
    sizeBytes: readInt(json['sizeBytes']),
    frameCount: readInt(json['frameCount']),
  );
}

GifUser? _userFromJson(Map<String, dynamic> json) {
  final displayName = readString(json['displayName']);
  if (displayName == null) return null;
  return GifUser(
    username: readString(json['username']) ?? '',
    displayName: displayName,
    avatarUrl: readString(json['avatarUrl']),
  );
}
