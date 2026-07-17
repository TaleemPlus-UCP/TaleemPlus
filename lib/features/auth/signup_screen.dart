import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.admin;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      phoneNumber: _phoneCtrl.text,
      password: _passwordCtrl.text,
      role: _selectedRole,
    );

    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      Navigator.pushReplacementNamed(
        context,
        auth.currentUser!.role.dashboardRoute,
      );
    } else if (auth.pendingApproval) {
      await _showPendingDialog();
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        ),
      );
    }
  }

  Future<void> _showPendingDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceAlt,
        title: const Text('Account created',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Your account is waiting for admin approval. '
              'You can log in once an admin approves it.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context); // back to login
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const OfflineBadge(),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _logo(),
                  const SizedBox(height: 16),
                  const Text(
                    'TaleemPlus',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Create your profile to join your local academy workspace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SELECT YOUR ROLE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _roleGrid(),
                  const SizedBox(height: 24),
                  _formCard(),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Sign Up',
                    icon: Icons.arrow_forward_rounded,
                    loading: loading,
                    onPressed: loading ? null : _submit,
                  ),
                  const SizedBox(height: 20),
                  _loginLink(),
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
        child: const Icon(Icons.menu_book_rounded,
            size: 32, color: AppColors.accent),
      ),
    );
  }

  Widget _roleGrid() {
    const roles = [
      (UserRole.admin, Icons.vpn_key_rounded),
      (UserRole.teacher, Icons.edit_note_rounded),
      (UserRole.student, Icons.school_rounded),
      (UserRole.parent, Icons.account_tree_rounded),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: roles.map((r) {
        final selected = _selectedRole == r.$1;
        return GestureDetector(
          onTap: () => setState(() => _selectedRole = r.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(r.$2,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 22),
                const SizedBox(height: 6),
                Text(
                  r.$1.label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          LabeledField(
            label: 'Full Name',
            hint: 'e.g. Muhammad Rakib',
            controller: _nameCtrl,
            validator: Validators.fullName,
            keyboardType: TextInputType.name,
          ),
          LabeledField(
            label: 'Email Address',
            hint: 'name${AppRules.emailDomain}',
            controller: _emailCtrl,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress,
          ),
          LabeledField(
            label: 'Phone Number',
            hint: '+92 300 1234567',
            controller: _phoneCtrl,
            validator: Validators.phone,
            keyboardType: TextInputType.phone,
          ),
          LabeledField(
            label: 'Password',
            hint: 'At least ${AppRules.minPasswordLength} characters',
            controller: _passwordCtrl,
            obscure: _obscure,
            validator: Validators.password,
            suffix: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          LabeledField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmCtrl,
            obscure: _obscureConfirm,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                Validators.confirmPassword(v, _passwordCtrl.text),
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                color: AppColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? ',
            style: TextStyle(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Log In',
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}