import 'package:flutter/material.dart';

/// Central color palette for TaleemPlus.
/// Extracted directly from the approved teal/cyan design mockups.
class AppColors {
  const AppColors._();

  // --- Brand accent (bright cyan buttons / highlights) ---
  static const Color accent = Color(0xFF17E9DF);
  static const Color accentDark = Color(0xFF0FBFB7);

  // --- Background gradient (Dark Mode: deep teal) ---
  static const Color bgTopDark = Color(0xFF0C3B3B);
  static const Color bgBottomDark = Color(0xFF061F1E);
  static const Color bgGlowCenter = Color(0xFF0E6E6E);

  // --- Background gradient (Light Mode: soft teal/white) ---
  static const Color bgTopLight = Color(0xFFF0FDFD);
  static const Color bgBottomLight = Color(0xFFE0F7F7);

  // --- Surfaces / cards ---
  static const Color surfaceDark = Color(0xFF0E3232);
  static const Color surfaceAltDark = Color(0xFF103A3A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFF5FBFB);
  
  static const Color inputFillDark = Color(0xFF0A1211);
  static const Color inputFillLight = Color(0xFFF0F4F4);
  
  static const Color borderDark = Color(0xFF1C4A4A);
  static const Color borderLight = Color(0xFFD0E0E0);

  // --- Text ---
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFF9CC0C0);
  static const Color textMutedDark = Color(0xFF6E8E8E);
  
  static const Color textPrimaryLight = Color(0xFF042020);
  static const Color textSecondaryLight = Color(0xFF4A6B6B);
  static const Color textMutedLight = Color(0xFF7A9E9E);
  
  static const Color textOnAccent = Color(0xFF042020); // dark text on cyan btn

  // --- Status ---
  static const Color danger = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);
  static const Color success = Color(0xFF3DD68C);

  // --- Legacy Aliases (to keep project compiling while refactoring) ---
  static const Color bgBottom = bgBottomDark; // Original background color
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted = textMutedDark;
  static const Color surface = surfaceDark;
  static const Color surfaceAlt = surfaceAltDark;
  static const Color border = borderDark;
  static const Color inputFill = inputFillDark;

  // --- Gradients ---
  static LinearGradient scaffoldGradient(bool isDark) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark 
        ? [bgTopDark, bgBottomDark] 
        : [bgTopLight, bgBottomLight],
  );

  static RadialGradient splashGradient(bool isDark) => RadialGradient(
    center: Alignment.center,
    radius: 1.1,
    colors: isDark 
        ? [bgGlowCenter, bgBottomDark] 
        : [const Color(0xFFB0F0F0), bgBottomLight],
    stops: const [0.0, 1.0],
  );

  static const LinearGradient accentButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, accentDark],
  );
}
