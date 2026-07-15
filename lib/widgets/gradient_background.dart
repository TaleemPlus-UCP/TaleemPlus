import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Full-screen teal gradient background used on auth + dashboard screens.
/// A faint centered logo watermark sits behind the content.
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
      child: Stack(
        children: [
          // Faint logo watermark in the background
          Center(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/Logo.png',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Actual screen content on top
          child,
        ],
      ),
    );
  }
}