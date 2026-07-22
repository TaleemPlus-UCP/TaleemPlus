import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../widgets/gradient_background.dart';
import '../../../data/models/app_user.dart';
import '../../../data/remote/auth_service.dart';

class AcademyContactScreen extends StatelessWidget {
  final String academyId;
  const AcademyContactScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academy Support',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: FutureBuilder<AppUser?>(
            future: AuthService().getProfile(academyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }

              final academy = snapshot.data;
              final name = academy?.academyName ?? "SRS Tech Matrix";
              final address =
                  academy?.academyAddress ?? "123 Education Lane, Lahore";
              final phone = academy?.academyPhone ?? "03014334151";

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildHeader(context, name),
                  const SizedBox(height: 32),
                  const Text('CONTACT CHANNELS',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _contactTile(
                    context,
                    'Official WhatsApp',
                    phone,
                    Icons.chat_bubble_rounded,
                    AppColors.success,
                    () => _openWhatsApp(context, phone),
                  ),
                  const SizedBox(height: 12),
                  _contactTile(
                    context,
                    'Helpline / Call',
                    phone,
                    Icons.call_rounded,
                    AppColors.accent,
                    () => _callNumber(context, phone),
                  ),
                  const SizedBox(height: 32),
                  _buildLocationCard(context, address),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _callNumber(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the dialer.")));
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    // wa.me expects digits only, with country code and no leading zero/+.
    var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) {
      digits = '92${digits.substring(1)}'; // Pakistan local -> country code
    }
    final uri = Uri.parse('https://wa.me/$digits');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open WhatsApp.")));
    }
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.school_rounded,
              size: 48, color: AppColors.accent),
        ),
        const SizedBox(height: 16),
        Text(name,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        const Text('Education with Excellence',
            style: TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _contactTile(BuildContext context, String title, String val,
      IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        subtitle: Text(val,
            style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.open_in_new_rounded,
            size: 18, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_rounded,
                  color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text('Location',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(address,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),
          const Text('VISTING HOURS',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const Text('Mon - Fri (09:00 AM - 05:00 PM)',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}
