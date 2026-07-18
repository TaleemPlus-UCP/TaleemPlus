import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart'; // NEW
import '../../core/utils/validators.dart';
import '../../data/remote/auth_service.dart';
import '../../logic/auth_provider.dart';
import '../../logic/session_provider.dart'; // NEW
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final saved = await context.read<AuthProvider>().loadSavedEmail();
    if (saved != null && mounted) {
      setState(() {
        _emailCtrl.text = saved;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      Navigator.pushReplacementNamed(
        context,
        auth.currentUser!.role.dashboardRoute,
      );
    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  Future<void> _biometricSignIn() async {
    final session = context.read<SessionProvider>();
    final auth = context.read<AuthProvider>();
    
    // Check if biometric is enabled for this account
    if (!session.biometricEnabled) {
      _showError("Biometric login is not enabled. Please login with password first and enable it in settings.");
      return;
    }

    final authenticated = await session.authenticateWithBiometrics();
    if (authenticated) {
      final savedEmail = await auth.loadSavedEmail();
      if (savedEmail != null) {
         // In a real high-security app, you'd store a secure token. 
         // Since we are offline-first with Firebase persistence, 
         // Firebase Auth often keeps the user logged in. 
         // This serves as a gateway.
         final user = await auth.tryRestoreSession();
         if (mounted && user != null) {
            Navigator.pushReplacementNamed(context, user.role.dashboardRoute);
         } else {
            _showError("Session expired. Please login with password.");
         }
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (Validators.email(email) != null) {
      _showError('Enter your ${AppRules.emailDomain} email first.');
      return;
    }
    try {
      await AuthService().sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent.')),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.center,
                    child: OfflineBadge(),
                  ),
                  const SizedBox(height: 28),
                  _logo(),
                  const SizedBox(height: 16),
                  Text(
                    'TaleemPlus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome back! Enter your credentials to securely access your local academy dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _card(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: 'Log In',
                          icon: Icons.login_rounded,
                          loading: loading,
                          onPressed: loading ? null : _submit,
                        ),
                      ),
                      if (context.watch<SessionProvider>().biometricEnabled) ...[
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: loading ? null : _biometricSignIn,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.textOnAccent,
                            fixedSize: const Size(56, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.fingerprint_rounded, size: 28),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _signupLink(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.accent.withValues(alpha: 0.15),
        ),
        child: Icon(Icons.menu_book_rounded,
            size: 34, color: context.appColors.textPrimary),
      ),
    );
  }

  Widget _card() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          LabeledField(
            label: 'Email or Unique ID',
            hint: 'Enter your email or unique ID...',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.emailOrId,
          ),
          LabeledField(
            label: 'Password',
            hint: 'Enter your password...',
            controller: _passwordCtrl,
            obscure: _obscure,
            textInputAction: TextInputAction.done,
            validator: Validators.password,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility : Icons.visibility_off,
                color: context.appColors.textMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.accent,
                  checkColor: AppColors.textOnAccent,
                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text('Remember Me',
                  style: TextStyle(color: context.appColors.textSecondary)),
              const Spacer(),
              TextButton(
                onPressed: _forgotPassword,
                child: Text('Forgot Password?',
                    style: TextStyle(color: context.appColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: TextStyle(color: context.appColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.signup),
          child: const Text(
            'Sign Up',
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
