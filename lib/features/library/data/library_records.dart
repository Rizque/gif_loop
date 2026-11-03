import 'package:gif_loop/features/gifs/data/dto/json_read.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/data/gif_json.dart';

class FavoriteRecord {
  const new({
    required this.gif,
    required this.previewFileName,
    required this.fullFileName,
    required this.addedAt,
  });

  static FavoriteRecord? fromJson(Map<String, dynamic> json) {
    final gifJson = readMap(json['gif']);
    final gif = gifJson == null ? null : gifFromJson(gifJson);
    final previewFileName = readString(json['previewFileName']);
    final fullFileName = readString(json['fullFileName']);
    final addedAt = DateTime.tryParse(readString(json['addedAt']) ?? '');
    if (gif == null ||
        previewFileName == null ||
        fullFileName == null ||
        addedAt == null) {
      return null;
    }
    return FavoriteRecord(
      gif: gif,
      previewFileName: previewFileName,
      fullFileName: fullFileName,
      addedAt: addedAt,
    );
  }

  final Gif gif;
  final String previewFileName;
  final String fullFileName;
  final DateTime addedAt;

  Map<String, Object?> toJson() => {
    'gif': gifToJson(gif),
    'previewFileName': previewFileName,
    'fullFileName': fullFileName,
    'addedAt': addedAt.toIso8601String(),
  };
}

class RemixRecord {
  const new({
    required this.id,
    required this.sourceGifId,
    required this.sourceTitle,
    required this.fileName,
    required this.width,
    required this.height,
    required this.frameCount,
    required this.durationMs,
    required this.sizeBytes,
    required this.createdAt,
  });

  static RemixRecord? fromJson(Map<String, dynamic> json) {
    final id = readString(json['id']);
    final fileName = readString(json['fileName']);
    final createdAt = DateTime.tryParse(readString(json['createdAt']) ?? '');
    if (id == null || fileName == null || createdAt == null) return null;
    return RemixRecord(
      id: id,
      sourceGifId: readString(json['sourceGifId']) ?? '',
      sourceTitle: readString(json['sourceTitle']) ?? '',
      fileName: fileName,
      width: readInt(json['width']) ?? 0,
      height: readInt(json['height']) ?? 0,
      frameCount: readInt(json['frameCount']) ?? 0,
      durationMs: readInt(json['durationMs']) ?? 0,
      sizeBytes: readInt(json['sizeBytes']) ?? 0,
      createdAt: createdAt,
    );
  }

  final String id;
  final String sourceGifId;
  final String sourceTitle;
  final String fileName;
  final int width;
  final int height;
  final int frameCount;
  final int durationMs;
  final int sizeBytes;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'sourceGifId': sourceGifId,
    'sourceTitle': sourceTitle,
    'fileName': fileName,
    'width': width,
    'height': height,
    'frameCount': frameCount,
    'durationMs': durationMs,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
  };
}
