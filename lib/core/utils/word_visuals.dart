import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Word pill colors + mini icons matching reference screenshot style.
abstract final class WordVisuals {
  static Color textColor(String word) {
    final key = word.toUpperCase();
    return _textColors[key] ??
        AppColors.marbleForWordChip(word).first;
  }

  static Color iconAccent(String word) {
    return textColor(word);
  }

  static void paintMiniIcon(Canvas canvas, Offset center, double size, String word) {
    final key = word.toUpperCase();
    switch (key) {
      case 'APPLE':
        _paintApple(canvas, center, size);
      case 'MANGO':
        _paintMango(canvas, center, size);
      case 'GRAPE':
      case 'GRAPES':
        _paintGrapes(canvas, center, size);
      case 'RED':
        _paintColorDot(canvas, center, size, const Color(0xFFE53935));
      case 'BLUE':
        _paintColorDot(canvas, center, size, const Color(0xFF1E6FE8));
      case 'GREEN':
        _paintColorDot(canvas, center, size, const Color(0xFF43C843));
      case 'YELLOW':
        _paintColorDot(canvas, center, size, const Color(0xFFFFC107));
      case 'ORANGE':
        _paintColorDot(canvas, center, size, const Color(0xFFFF8C00));
      default:
        _paintGeneric(canvas, center, size, textColor(word));
    }
  }

  static const Map<String, Color> _textColors = {
    'APPLE': Color(0xFFE53935),
    'MANGO': Color(0xFFFF8C00),
    'GRAPE': Color(0xFF8E24FF),
    'GRAPES': Color(0xFF8E24FF),
    'RED': Color(0xFFE53935),
    'BLUE': Color(0xFF1E6FE8),
    'GREEN': Color(0xFF43C843),
    'YELLOW': Color(0xFFFFB020),
    'ORANGE': Color(0xFFFF8C00),
    'PINK': Color(0xFFE91E8C),
    'PURPLE': Color(0xFF8E24FF),
    'WHITE': Color(0xFFB0BEC5),
    'BLACK': Color(0xFF455A64),
  };

  static void _paintApple(Canvas canvas, Offset c, double s) {
    canvas.drawCircle(
      c.translate(0, s * 0.05),
      s * 0.42,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-s * 0.1, -s * 0.1),
          s * 0.5,
          [const Color(0xFFFF6B6B), const Color(0xFFC62828)],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(s * 0.12, -s * 0.42),
        width: s * 0.22,
        height: s * 0.14,
      ),
      Paint()..color = const Color(0xFF43C843),
    );
  }

  static void _paintMango(Canvas canvas, Offset c, double s) {
    final path = Path()
      ..moveTo(c.dx, c.dy - s * 0.45)
      ..quadraticBezierTo(
        c.dx + s * 0.5,
        c.dy,
        c.dx,
        c.dy + s * 0.45,
      )
      ..quadraticBezierTo(
        c.dx - s * 0.5,
        c.dy,
        c.dx,
        c.dy - s * 0.45,
      );
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          c.translate(0, -s * 0.4),
          c.translate(0, s * 0.4),
          [const Color(0xFFFFD166), const Color(0xFFFF8C00)],
        ),
    );
  }

  static void _paintGrapes(Canvas canvas, Offset c, double s) {
    final purple = const Color(0xFF8E24FF);
    for (var row = 0; row < 3; row++) {
      final count = row == 1 ? 3 : 2;
      for (var col = 0; col < count; col++) {
        final ox = (col - (count - 1) / 2) * s * 0.28;
        final oy = row * s * 0.26 - s * 0.2;
        canvas.drawCircle(
          c.translate(ox, oy),
          s * 0.18,
          Paint()..color = Color.lerp(purple, Colors.white, row * 0.08)!,
        );
      }
    }
  }

  static void _paintColorDot(
    Canvas canvas,
    Offset c,
    double s,
    Color color,
  ) {
    canvas.drawCircle(
      c,
      s * 0.38,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(-s * 0.12, -s * 0.12),
          s * 0.45,
          [Color.lerp(color, Colors.white, 0.35)!, color],
        ),
    );
  }

  static void _paintGeneric(Canvas canvas, Offset c, double s, Color color) {
  canvas.drawCircle(
      c,
      s * 0.35,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          s * 0.4,
          [Color.lerp(color, Colors.white, 0.3)!, color],
        ),
    );
  }
}

class WordMiniIcon extends StatelessWidget {
  const WordMiniIcon({super.key, required this.word, this.size = 22});

  final String word;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WordMiniIconPainter(word: word),
    );
  }
}

class _WordMiniIconPainter extends CustomPainter {
  const _WordMiniIconPainter({required this.word});

  final String word;

  @override
  void paint(Canvas canvas, Size size) {
    WordVisuals.paintMiniIcon(
      canvas,
      Offset(size.width / 2, size.height / 2),
      size.width,
      word,
    );
  }

  @override
  bool shouldRepaint(covariant _WordMiniIconPainter oldDelegate) =>
      oldDelegate.word != word;
}
