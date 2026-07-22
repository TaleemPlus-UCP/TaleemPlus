import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../logic/auth_provider.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/gradient_background.dart';
import '../../data/remote/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Admin only
  final _academyNameCtrl = TextEditingController();
  final _academyAddressCtrl = TextEditingController();

  // Member only
  final _academyCodeCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.student;

  bool _obscure = true;
  bool _isSearchingAcademy = false;
  String? _linkedAcademyId;
  String? _linkedAcademyName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Reset state when switching tabs
        _linkedAcademyId = null;
        _linkedAcademyName = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _academyNameCtrl.dispose();
    _academyAddressCtrl.dispose();
    _academyCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    if (_academyCodeCtrl.text.isEmpty) return;
    setState(() => _isSearchingAcademy = true);

    try {
      final academy =
          await AuthService().findAcademyByCode(_academyCodeCtrl.text);
      if (mounted) {
        setState(() {
          _isSearchingAcademy = false;
          if (academy != null) {
            _linkedAcademyId = academy.uid;
            _linkedAcademyName = academy.academyName;
          } else {
            _linkedAcademyId = null;
            _linkedAcademyName = null;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text("Invalid Academy Code!"),
                backgroundColor: AppColors.danger));
          }
        });
      }
    } catch (e) {
      setState(() => _isSearchingAcademy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isAdminFlow = _tabController.index == 0;

    // Auto-verify code if not already verified for Members
    if (!isAdminFlow && _linkedAcademyId == null) {
      if (_academyCodeCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Academy Code is required."),
            backgroundColor: AppColors.danger));
        return;
      }
      await _verifyCode();
      if (!mounted) return;
      if (_linkedAcademyId == null) {
        return; // _verifyCode will show its own snackbar
      }
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signUp(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      phoneNumber: _phoneCtrl.text,
      password: _passCtrl.text,
      role: isAdminFlow ? UserRole.admin : _selectedRole,
      academyName: isAdminFlow ? _academyNameCtrl.text : _linkedAcademyName,
      academyId: isAdminFlow ? null : _linkedAcademyId,
      academyAddress: isAdminFlow ? _academyAddressCtrl.text : null,
      academyPhone: isAdminFlow ? _phoneCtrl.text : null,
    );

    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      if (isAdminFlow) {
        _showAcademyCreatedDialog(auth.currentUser!.academyCode!);
      } else {
        await _showPendingDialog();
      }
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.danger));
    }
  }

  void _showAcademyCreatedDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Academy Registered!",
            style: TextStyle(
                color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Your academy is ready. Share this code with your teachers and students to join:",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent)),
              child: Text(code,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
            ),
          ],
        ),
        actions: [
          PrimaryButton(
              label: "ENTER DASHBOARD",
              onPressed: () => Navigator.pushReplacementNamed(
                  context, AppRoutes.adminDashboard)),
        ],
      ),
    );
  }

  Future<void> _showPendingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Request Sent"),
        content: const Text(
            "Your account is pending approval from the Academy Admin. You can login once they approve you."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTypeToggle(),
                        const SizedBox(height: 32),
                        _buildFormFields(),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          label: _tabController.index == 0
                              ? "REGISTER ACADEMY"
                              : "JOIN AS ${_selectedRole.name.toUpperCase()}",
                          icon: Icons.arrow_forward_rounded,
                          loading: loading,
                          onPressed: loading ? null : _submit,
                        ),
                        const SizedBox(height: 24),
                        _loginLink(),
                      ],
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context)),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppColors.accentButton,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.textOnAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
        unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5),
        tabs: const [
          Tab(text: "REGISTER ACADEMY"),
          Tab(text: "JOIN ACADEMY"),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    final isAdmin = _tabController.index == 0;
    return Column(
      children: [
        LabeledField(
            label: "Full Name",
            hint: "Enter your name",
            controller: _nameCtrl,
            validator: Validators.fullName),
        LabeledField(
            label: "Email Address",
            hint: "Enter email",
            controller: _emailCtrl,
            validator: Validators.email,
            keyboardType: TextInputType.emailAddress),
        LabeledField(
            label: "Phone Number",
            hint: "+92...",
            controller: _phoneCtrl,
            validator: Validators.phone,
            keyboardType: TextInputType.phone),
        if (isAdmin) ...[
          LabeledField(
              label: "Academy Name",
              hint: "e.g. SRS Tech Matrix",
              controller: _academyNameCtrl,
              validator: (v) => v!.isEmpty ? "Required" : null),
          LabeledField(
              label: "Academy Address",
              hint: "Full location",
              controller: _academyAddressCtrl),
        ] else ...[
          const Align(
              alignment: Alignment.centerLeft,
              child: Text("I AM A:",
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1))),
          const SizedBox(height: 12),
          _buildRolePicker(),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                  child: LabeledField(
                      label: "Academy Code",
                      hint: "TP-XXXXX",
                      controller: _academyCodeCtrl)),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isSearchingAcademy ? null : _verifyCode,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: _linkedAcademyId != null
                              ? AppColors.success
                              : AppColors.accent,
                          width: 1.2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: _linkedAcademyId != null
                          ? AppColors.success.withValues(alpha: 0.05)
                          : Colors.transparent,
                    ),
                    child: _isSearchingAcademy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent))
                        : Icon(
                            _linkedAcademyId != null
                                ? Icons.verified_user_rounded
                                : Icons.vpn_key_rounded,
                            color: _linkedAcademyId != null
                                ? AppColors.success
                                : AppColors.accent),
                  ),
                ),
              ),
            ],
          ),
          if (_linkedAcademyName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text("Joining: $_linkedAcademyName",
                  style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
        ],
        LabeledField(
          label: "Password",
          hint: "Min 6 chars",
          controller: _passCtrl,
          obscure: _obscure,
          validator: Validators.password,
          suffix: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textMuted),
              onPressed: () => setState(() => _obscure = !_obscure)),
        ),
        LabeledField(
            label: "Confirm Password",
            hint: "Re-enter password",
            controller: _confirmCtrl,
            obscure: _obscure,
            validator: (v) => Validators.confirmPassword(v, _passCtrl.text)),
      ],
    );
  }

  Widget _buildRolePicker() {
    final roles = [UserRole.teacher, UserRole.student, UserRole.parent];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: roles.map((role) {
        final selected = _selectedRole == role;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: selected ? AppColors.accentButton : null,
                color:
                    selected ? null : AppColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : AppColors.border.withValues(alpha: 0.5)),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  role.name.toUpperCase(),
                  style: TextStyle(
                    color: selected
                        ? AppColors.textOnAccent
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ",
            style: TextStyle(color: AppColors.textSecondary)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text("Log In",
              style: TextStyle(
                  color: AppColors.accent, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
