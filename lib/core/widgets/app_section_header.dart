import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Reusable section header component.
///
/// Provides consistent hierarchy, spacing, optional leading icon,
/// subtitle, and trailing action button across all screens.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.padding,
  });

  /// The section title.
  final String title;

  /// Optional supporting text under the title.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing widget (e.g. text button, badge, action).
  final Widget? trailing;

  /// Custom padding around the section header.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppIconSize.sm + 4,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: isDark
                        ? const Color(0xFFE8ECF0)
                        : AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.start,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? const Color(0xFF9BB3C6)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing! else const SizedBox.shrink(),
        ],
      ),
    );
  }
}
