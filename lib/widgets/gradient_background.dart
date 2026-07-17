import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: useSplashGlow
            ? AppColors.splashGradient
            : AppColors.scaffoldGradient,
      ),
      child: child,
    );
  }
}