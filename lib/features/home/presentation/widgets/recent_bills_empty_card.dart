import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

/// Compact, honest empty state displayed in the Recent Bills section.
///
/// Indicates that saved workshop bills will appear here once created,
/// without fabricating sample customers, amounts, or analytics.
class RecentBillsEmptyCard extends StatelessWidget {
  const RecentBillsEmptyCard({super.key, required this.onNewBill});

  final VoidCallback onNewBill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Recent Bills',
          subtitle: 'Recently generated invoices for repair jobs',
          icon: Icons.history_edu_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceElevatedDark
                      : AppColors.primary.withAlpha(12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_outlined,
                  size: 22,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primary.withAlpha(140),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No bills yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saved bills will appear here.',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? const Color(0xFF9BB3C6)
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Create New Bill',
                icon: Icons.add_rounded,
                onPressed: onNewBill,
                fullWidth: false,
                semanticLabel: 'Create first bill from empty state',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
