import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

/// Quick access tiles for useful, supported destinations on the dashboard.
///
/// Provides quick shortcuts to Bill History and Company Settings without
/// visual clutter or unsupported placeholder actions.
class DashboardQuickAccess extends StatelessWidget {
  const DashboardQuickAccess({
    super.key,
    required this.onHistory,
    required this.onSettings,
  });

  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Quick Access',
          subtitle: 'Direct shortcuts to key workshop functions',
          icon: Icons.flash_on_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _QuickTile(
                icon: Icons.receipt_long_rounded,
                label: 'Bill History',
                subtitle: 'View saved bills',
                onTap: onHistory,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _QuickTile(
                icon: Icons.tune_rounded,
                label: 'Settings',
                subtitle: 'Workshop info',
                onTap: onSettings,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      semanticLabel: '$label: $subtitle',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs + 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
              size: AppIconSize.md,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? const Color(0xFF9BB3C6) : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
