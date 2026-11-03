Map<String, dynamic>? readMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

String? readString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

// GIPHY encodes most numbers (width, height, size, frames) as strings.
int? readInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};
