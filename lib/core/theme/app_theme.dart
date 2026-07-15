import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBottom,
      primaryColor: AppColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: AppColors.textOnAccent,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.accent, width: 1.4),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.4),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceAlt,
        contentTextStyle: TextStyle(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
