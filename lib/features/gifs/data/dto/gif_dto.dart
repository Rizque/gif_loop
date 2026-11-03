import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/data/dto/rendition_dto.dart';
import 'package:gif_loop/features/gifs/data/dto/user_dto.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class GifDto {
  const new({
    this.id,
    this.title,
    this.url,
    this.bitlyUrl,
    this.username,
    this.rating,
    this.importDatetime,
    this.user,
    this.fixedWidth,
    this.downsizedLarge,
    this.original,
  });

  factory fromJson(Map<String, dynamic> json) {
    final images = readMap(json['images']);
    final user = readMap(json['user']);
    return GifDto(
      id: readString(json['id']),
      title: readString(json['title']),
      url: readString(json['url']),
      bitlyUrl: readString(json['bitly_url']),
      username: readString(json['username']),
      rating: readString(json['rating']),
      importDatetime: readString(json['import_datetime']),
      user: user == null ? null : UserDto.fromJson(user),
      fixedWidth: _rendition(images, 'fixed_width'),
      downsizedLarge: _rendition(images, 'downsized_large'),
      original: _rendition(images, 'original'),
    );
  }

  final String? id;
  final String? title;
  final String? url;
  final String? bitlyUrl;
  final String? username;
  final String? rating;
  final String? importDatetime;
  final UserDto? user;
  final RenditionDto? fixedWidth;
  final RenditionDto? downsizedLarge;
  final RenditionDto? original;

  // Old GIFs report placeholder import dates such as "0000-00-00 00:00:00".
  static const int _firstValidImportYear = 1990;

  Gif? toDomain() {
    final id = this.id;
    final full = downsizedLarge?.toDomain() ?? original?.toDomain();
    final preview = fixedWidth?.toDomain(preferWebp: true) ?? full;
    if (id == null || preview == null || full == null) return null;
    final pageUrl = url ?? 'https://giphy.com/gifs/$id';
    return Gif(
      id: id,
      title: title ?? Strings.untitled,
      url: pageUrl,
      shareUrl: bitlyUrl ?? pageUrl,
      username: username ?? '',
      user: user?.toDomain(),
      rating: rating ?? '',
      importDateTime: _parseImportDate(importDatetime),
      preview: preview,
      full: full,
    );
  }

  static RenditionDto? _rendition(Map<String, dynamic>? images, String key) {
    final json = readMap(images?[key]);
    return json == null ? null : RenditionDto.fromJson(json);
  }

  static DateTime? _parseImportDate(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    return date != null && date.year >= _firstValidImportYear ? date : null;
  }
}
