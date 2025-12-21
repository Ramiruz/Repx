import 'package:flutter/material.dart';

/// 🎨 Paleta de colores PREMIUM - Dark Theme profesional
class AppColors {
  // Colores primarios - Cyan eléctrico y Purple vibrante
  static const Color primaryCyan = Color(0xFF00F5FF);
  static const Color primaryPurple = Color(0xFF9D4EDD);
  static const Color accentMagenta = Color(0xFFFF006E);

  // Colores de estado
  static const Color successGreen = Color(0xFF06FFA5);
  static const Color warningYellow = Color(0xFFFFD60A);
  static const Color errorPink = Color(0xFFFF006E);

  // Backgrounds oscuros
  static const Color darkBg = Color(0xFF0A0E27);
  static const Color cardBg = Color(0xFF1A1F3A);
  static const Color cardBgLight = Color(0xFF252B4A);

  // Glass effects
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color glassLight = Color(0x44FFFFFF);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryPurple],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, Color(0xFF00FFA3)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warningYellow, Color(0xFFFFE55C)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorPink, Color(0xFFFF0080)],
  );

  static LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkBg,
      cardBg,
      const Color(0xFF0F1123),
    ],
  );
}
