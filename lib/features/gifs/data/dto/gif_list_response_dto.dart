import 'package:gif_loop/features/gifs/data/dto/gif_dto.dart';
import 'package:gif_loop/features/gifs/data/dto/json_read.dart';

class GifListResponseDto {
  const new({
    required this.data,
    this.offset,
    this.count,
    this.totalCount,
    this.status,
    this.responseId,
  });

  factory fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) {
      throw const FormatException('GIPHY list response has no data array');
    }
    final pagination = readMap(json['pagination']);
    final meta = readMap(json['meta']);
    return GifListResponseDto(
      data: data.map(readMap).nonNulls.map(GifDto.fromJson).toList(),
      offset: readInt(pagination?['offset']),
      count: readInt(pagination?['count']),
      totalCount: readInt(pagination?['total_count']),
      status: readInt(meta?['status']),
      responseId: switch (meta?['response_id']) {
        final String id => id,
        _ => null,
      },
    );
  }

  final List<GifDto> data;
  final int? offset;
  final int? count;
  final int? totalCount;
  final int? status;
  final String? responseId;

  // GIPHY documents a "synthetic response" (status 200, empty response_id,
  // empty body) that must be treated as an error.
  bool get isSynthetic => status == 200 && responseId == '' && data.isEmpty;
}
