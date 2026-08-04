import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart'; // NEW
import '../../core/utils/validators.dart';
import '../../core/web/web_breakpoints.dart';
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

    if (!session.biometricEnabled) {
      _showError("Biometric login is not enabled in settings.");
      return;
    }

    final authenticated = await session.authenticateWithBiometrics();
    if (authenticated) {
      final email = await auth.loadSavedEmail();
      final password = await session.getSavedPassword();

      if (email != null && password != null) {
        final ok = await auth.signIn(
          email: email,
          password: password,
          rememberMe: true,
        );
        if (mounted && ok && auth.currentUser != null) {
          Navigator.pushReplacementNamed(
              context, auth.currentUser!.role.dashboardRoute);
        } else if (auth.errorMessage != null) {
          _showError(auth.errorMessage!);
        }
      } else {
        _showError("Credentials not found. Please login with password once.");
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (Validators.email(email) != null) {
      _showError('Please enter a valid email address first.');
      return;
    }

    // Accounts that never set a recovery question (e.g. created before
    // this feature, or by an admin who skipped it) fall back to the plain
    // emailed reset link so they aren't locked out of recovery entirely.
    final question = await AuthService().getSecurityQuestion(email);
    if (!mounted) return;
    if (question == null) {
      await _sendResetEmail(email);
      return;
    }
    await _showSecurityAnswerDialog(email, question);
  }

  Future<void> _sendResetEmail(String email) async {
    try {
      await AuthService().sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Password reset link sent — check your email (and spam folder).')),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
    }
  }

  /// Verifies the account's security answer before re-sending the reset
  /// email. This is a self-service identity check, not a password change —
  /// Firebase only lets a password actually change via that emailed link
  /// (or an active session), so the answer being right just unlocks the
  /// same [sendPasswordReset] call [_forgotPassword] would've made anyway.
  Future<void> _showSecurityAnswerDialog(String email, String question) async {
    final answerCtrl = TextEditingController();
    String? error;
    bool verifying = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surfaceAlt,
          title: const Text('Verify Your Identity',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              LabeledField(
                  label: 'Your Answer', hint: '', controller: answerCtrl),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(error!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: verifying
                  ? null
                  : () async {
                      setDialogState(() {
                        verifying = true;
                        error = null;
                      });
                      final ok = await AuthService()
                          .verifySecurityAnswer(email, answerCtrl.text);
                      if (!ok) {
                        setDialogState(() {
                          verifying = false;
                          error = 'Incorrect answer. Please try again.';
                        });
                        return;
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _sendResetEmail(email);
                    },
              child: Text(verifying ? 'VERIFYING...' : 'VERIFY',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
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
    final isWebWide = kIsWeb && !WebBreakpoints.isCompact(context);

    final form = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
    );

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: isWebWide
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: form,
                    ),
                  )
                : form,
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
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          LabeledField(
            label: 'Email',
            hint: 'Enter your email...',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.accent,
                      checkColor: AppColors.textOnAccent,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember Me',
                      style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 13)),
                ],
              ),
              TextButton(
                onPressed: _forgotPassword,
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('Forgot Password?',
                    style: TextStyle(
                        color: context.appColors.textSecondary, fontSize: 13)),
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
            style:
                TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
