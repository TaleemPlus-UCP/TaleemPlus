import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../logic/theme_provider.dart';

/// Full-screen teal gradient background used on auth + dashboard screens.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useSplashGlow;

  const GradientBackground({
    super.key,
    required this.child,
    this.useSplashGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    // Light mode renders flat (no gradient "fog") per the redesigned light
    // theme — the teal glow gradient is a dark-mode-only design element.
    if (!isDark && !useSplashGlow) {
      return ColoredBox(color: AppColors.bgBottomLight, child: child);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: useSplashGlow
            ? AppColors.splashGradient(isDark)
            : AppColors.scaffoldGradient(isDark),
      ),
      child: child,
    );
  }
}
