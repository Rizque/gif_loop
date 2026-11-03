import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif_rendition.dart';

class RenditionDto {
  const new({
    this.url,
    this.webp,
    this.width,
    this.height,
    this.size,
    this.frames,
  });

  factory fromJson(Map<String, dynamic> json) => RenditionDto(
    url: readString(json['url']),
    webp: readString(json['webp']),
    width: readInt(json['width']),
    height: readInt(json['height']),
    size: readInt(json['size']),
    frames: readInt(json['frames']),
  );

  final String? url;
  final String? webp;
  final int? width;
  final int? height;
  final int? size;
  final int? frames;

  GifRendition? toDomain({bool preferWebp = false}) {
    final source = preferWebp ? webp ?? url : url;
    if (source == null) return null;
    return GifRendition(
      url: source,
      width: width ?? 0,
      height: height ?? 0,
      sizeBytes: size,
      frameCount: frames,
    );
  }
}
