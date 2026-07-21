import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color darkBg = Color(0xFF0F1923);
  static const Color cardBg = Color(0xFF1A2635);
  static const Color accentBlue = Color(0xFF00B4D8);
  static const Color accentCyan = Color(0xFF48CAE4);
  static const Color accentGold = Color(0xFFFFD166);
  static const Color accentGreen = Color(0xFF06D6A0);
  static const Color accentRed = Color(0xFFEF476F);
  static const Color accentLime = Color(0xFF90E0EF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textBody = Color(0xFFADB5BD);
  static const Color textMuted = Color(0xFF6C757D);
  static const Color border = Color(0xFF2D3E50);
  static const Color junkGrey = Color(0xFF5A6A7A);
  static const Color hintGhost = Color(0x66FFFFFF);

  // Bouncy Match-style nebula palette
  static const Color nebulaBlue = Color(0xFF1E88E5);
  static const Color nebulaPurple = Color(0xFF7C4DFF);
  static const Color bubbleGlow = Color(0xFF40C4FF);
  static const Color bubbleCore = Color(0xFF1565C0);
  static const Color bubbleDeep = Color(0xFF0D47A1);

  static const List<Color> superBallGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFFD166),
    Color(0xFF06D6A0),
    Color(0xFF48CAE4),
    Color(0xFFB388FF),
  ];

  static const Map<String, List<Color>> ballColors = {
    'Colors': [Color(0xFF0077B6), Color(0xFF00B4D8)],
    'Fruits': [Color(0xFFFF9F1C), Color(0xFFFFBF69)],
    'Vegetables': [Color(0xFF2D6A4F), Color(0xFF40916C)],
    'Animals': [Color(0xFF6F4E37), Color(0xFF8B7355)],
    'Flowers': [Color(0xFFE879F9), Color(0xFFF0ABFC)],
    'Asian Countries': [Color(0xFF023E8A), Color(0xFF0077B6)],
    'World Countries': [Color(0xFF023E8A), Color(0xFF0096C7)],
    'Sports': [Color(0xFFD00000), Color(0xFFFF6B6B)],
    'Planets': [Color(0xFF03045E), Color(0xFF0077B6)],
    'Months': [Color(0xFF7209B7), Color(0xFF9D4EDD)],
    'World Cities': [Color(0xFF1B4332), Color(0xFF40916C)],
    'Birds': [Color(0xFF52B788), Color(0xFF95D5B2)],
    'Trees': [Color(0xFF2D6A4F), Color(0xFF52B788)],
    'Gems': [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
    'Currencies': [Color(0xFFB8860B), Color(0xFFFFD166)],
    'Body Parts': [Color(0xFFE63946), Color(0xFFFF6B6B)],
    'Instruments': [Color(0xFF6A040F), Color(0xFFDC2F02)],
    'Professions': [Color(0xFF495057), Color(0xFF6C757D)],
    'Pakistani Cities': [Color(0xFF006D77), Color(0xFF83C5BE)],
    'Elements': [Color(0xFF370617), Color(0xFF9D0208)],
    'Oceans & Seas': [Color(0xFF03045E), Color(0xFF0077B6)],
    'Rivers': [Color(0xFF0077B6), Color(0xFF48CAE4)],
    'Landmarks': [Color(0xFF6A040F), Color(0xFFDC2F02)],
    'Foods': [Color(0xFFE85D04), Color(0xFFF48C06)],
    'Dances': [Color(0xFF9D0208), Color(0xFFE85D04)],
    'Cricketers': [Color(0xFF006D77), Color(0xFF00B4D8)],
    'Superheroes': [Color(0xFF370617), Color(0xFF6A040F)],
    'default': [Color(0xFF00B4D8), Color(0xFF48CAE4)],
  };

  static List<Color> forCategory(String category) {
    return ballColors[category] ?? ballColors['default']!;
  }

  /// Vibrant gel-bubble palette (reference screenshot).
  static const List<List<Color>> marblePalette = [
    [Color(0xFFFF4D4D), Color(0xFFE53935)],
    [Color(0xFF3D8BFF), Color(0xFF1E6FE8)],
    [Color(0xFF6FE647), Color(0xFF43C843)],
    [Color(0xFFFFB020), Color(0xFFFF8C00)],
    [Color(0xFFB44DFF), Color(0xFF8E24FF)],
    [Color(0xFFFF5DA2), Color(0xFFE91E8C)],
    [Color(0xFF2ED9E8), Color(0xFF00ACC1)],
    [Color(0xFFFFEB3B), Color(0xFFFFC107)],
    [Color(0xFF7C6CFF), Color(0xFF5C4DFF)],
    [Color(0xFF26D9A3), Color(0xFF00BFA5)],
  ];

  static const Color neonPurple = Color(0xFFB388FF);
  static const Color neonGold = Color(0xFFFFD54F);

  static const Map<String, List<Color>> wordMarbleColors = {
    'RED': [Color(0xFFFF4D4D), Color(0xFFE53935)],
    'BLUE': [Color(0xFF3D8BFF), Color(0xFF1E6FE8)],
    'GREEN': [Color(0xFF6FE647), Color(0xFF43C843)],
    'YELLOW': [Color(0xFFFFEB3B), Color(0xFFFFC107)],
    'ORANGE': [Color(0xFFFFB020), Color(0xFFFF8C00)],
    'PINK': [Color(0xFFFF5DA2), Color(0xFFE91E8C)],
    'PURPLE': [Color(0xFFB44DFF), Color(0xFF8E24FF)],
    'WHITE': [Color(0xFFF5F5F5), Color(0xFFB0BEC5)],
    'BLACK': [Color(0xFF607D8B), Color(0xFF37474F)],
  };

  static List<Color> marbleForBall(String ballId) {
    final i = ballId.hashCode.abs() % marblePalette.length;
    return marblePalette[i];
  }

  static List<Color> marbleForWordChip(String word) {
    return wordMarbleColors[word.toUpperCase()] ??
        marblePalette[word.hashCode.abs() % marblePalette.length];
  }
}
