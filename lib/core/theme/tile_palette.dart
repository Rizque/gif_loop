import 'package:flutter/material.dart';

abstract final class TilePalette {
  static const List<Color> _colors = [
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFFFA726),
    Color(0xFFEC407A),
  ];

  static Color colorAt(int index) => _colors[index % _colors.length];
}
