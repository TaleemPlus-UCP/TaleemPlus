import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/gradient_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Logo: pops in with a soft bounce (0% - 45% of the timeline)
    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
    );

    // Title "TaleemPlus": slides up + fades in (35% - 65%)
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline: fades in last (60% - 90%)
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.60, 0.90, curve: Curves.easeIn),
    );

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    // Restore any existing session in parallel with a minimum splash time.
    final restoreFuture = auth.tryRestoreSession();
    await Future.delayed(const Duration(milliseconds: 2800));
    final user = await restoreFuture;

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, user.role.dashboardRoute);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        useSplashGlow: true,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ---- Animated Logo ----
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.10),
                            boxShadow: [
                              BoxShadow(
                                color:
                                AppColors.accent.withValues(alpha: 0.35),
                                blurRadius: 50,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/splash_Logo.png',
                            width: 96,
                            height: 96,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ---- Animated App Name: "TaleemPlus" ----
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Taleem',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: 'Plus',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.6),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ---- Tagline ----
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        'AI-POWERED. FULLY OFFLINE.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Bottom progress bar ----
              Positioned(
                left: 40,
                right: 40,
                bottom: 40,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Color(0x33FFFFFF),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}