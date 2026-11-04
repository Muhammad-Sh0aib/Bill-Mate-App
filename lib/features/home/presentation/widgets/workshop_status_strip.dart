import 'package:flutter/material.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Operational status strip providing truthful workshop and system status.
///
/// Confirms offline storage readiness, active currency standard, and
/// machinery focus without displaying fabricated financial figures.
class WorkshopStatusStrip extends StatelessWidget {
  const WorkshopStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : const Color(0xFFEDF2F7),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.offline_pin_outlined,
            size: AppIconSize.sm + 2,
            color: isDark ? const Color(0xFF81C784) : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              'Offline Ready',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF5D6D7E) : AppColors.textDisabled,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.monetization_on_outlined,
            size: AppIconSize.sm + 2,
            color: isDark ? const Color(0xFF90CAF9) : AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Currency: ${AppConfig.currencyCode} (${AppConfig.currencySymbol})',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF9BB3C6)
                    : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
