import 'package:flutter/material.dart';

/// Central color palette for TaleemPlus.
/// Extracted directly from the approved teal/cyan design mockups.
class AppColors {
  AppColors._();

  // --- Brand accent (bright cyan buttons / highlights) ---
  static const Color accent = Color(0xFF17E9DF);
  static const Color accentDark = Color(0xFF0FBFB7);

  // --- Background gradient (deep teal) ---
  static const Color bgTop = Color(0xFF0C3B3B);
  static const Color bgBottom = Color(0xFF061F1E);
  static const Color bgGlowCenter = Color(0xFF0E6E6E); // splash radial glow

  // --- Surfaces / cards ---
  static const Color surface = Color(0xFF0E3232);
  static const Color surfaceAlt = Color(0xFF103A3A);
  static const Color inputFill = Color(0xFF0A1211); // near-black input fields
  static const Color border = Color(0xFF1C4A4A);

  // --- Text ---
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CC0C0);
  static const Color textMuted = Color(0xFF6E8E8E);
  static const Color textOnAccent = Color(0xFF042020); // dark text on cyan btn

  // --- Status ---
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);
  static const Color success = Color(0xFF3DD68C);

  // --- Gradients ---
  static const LinearGradient scaffoldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgBottom],
  );

  static const RadialGradient splashGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.1,
    colors: [bgGlowCenter, bgBottom],
    stops: [0.0, 1.0],
  );

  static const LinearGradient accentButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentDark],
  );
}
