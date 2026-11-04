import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../company_settings/application/company_settings_providers.dart';

/// Displays the workshop's company identity on the dashboard.
///
/// Shows company name, contact phone, and specialty badge. Tapping the
/// card navigates directly to Settings so details can be reviewed.
class WorkshopIdentityCard extends ConsumerWidget {
  const WorkshopIdentityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(companySettingsProvider);
    final companyName =
        settings.asData?.value.name ?? AppConfig.defaultCompanyName;
    final companyPhone =
        settings.asData?.value.phone ?? AppConfig.defaultCompanyPhone;

    return AppCard(
      onTap: () => context.goNamed(RouteNames.settingsName),
      semanticLabel: '$companyName, Phone $companyPhone. Tap to view settings.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.primary.withAlpha(16),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2C3E50)
                    : AppColors.primary.withAlpha(25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.precision_manufacturing_rounded,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        companyName,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: isDark
                              ? const Color(0xFFE8ECF0)
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF132D19)
                            : AppColors.successBackground,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Active',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF9BB3C6)
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        companyPhone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Offset Printing Press Machinery',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? const Color(0xFF7E93A8)
                        : AppColors.textSecondary.withAlpha(190),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? const Color(0xFF5D6D7E) : AppColors.textDisabled,
            size: 20,
          ),
        ],
      ),
    );
  }
}
