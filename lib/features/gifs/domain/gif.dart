import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';
import 'package:gif_loop/features/gifs/domain/gif_user.dart';

class Gif extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.url,
    required this.shareUrl,
    required this.username,
    required this.rating,
    required this.preview,
    required this.full,
    this.user,
    this.importDateTime,
  });

  final String id;
  final String title;
  final String url;
  final String shareUrl;
  final String username;
  final GifUser? user;
  final String rating;
  final DateTime? importDateTime;
  final GifRendition preview;
  final GifRendition full;

  String? get authorName => user?.displayName ?? _nonEmpty(username);

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;

  @override
  List<Object?> get props => [
    id,
    title,
    url,
    shareUrl,
    username,
    user,
    rating,
    importDateTime,
    preview,
    full,
  ];
}
