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
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();
    // Restore any existing session in parallel with a minimum splash time.
    final restoreFuture = auth.tryRestoreSession();
    await Future.delayed(const Duration(milliseconds: 2200));
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
                child: FadeTransition(
                  opacity: _fade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.30),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/splash_Logo.png',
                          width: 90,
                          height: 90,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'AI-POWERED. FULLY OFFLINE.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 40,
                right: 40,
                bottom: 40,
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
            ],
          ),
        ),
      ),
    );
  }
}