import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/theme_extensions.dart';

/// Reusable mobile stat tile (icon badge + value + label) for the four role
/// dashboards' "at a glance" widgets — replaces each dashboard's own
/// bespoke `_statCard` method so the same visual is defined once. Mirrors
/// the web redesign's `WebStatCard` (lib/widgets/web/web_cards.dart), kept
/// as a separate mobile-only widget the same way the rest of the redesign
/// keeps mobile and web visuals independently defined.
class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.accent;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 18),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value,
                    style: TextStyle(
                        color: context.appColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
