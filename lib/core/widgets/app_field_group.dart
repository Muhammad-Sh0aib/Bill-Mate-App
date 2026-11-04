import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/theme/app_colors.dart';
import 'app_card.dart';

/// Layout container for grouping related form fields into a visually
/// coherent block with an optional header and description.
class AppFieldGroup extends StatelessWidget {
  const AppFieldGroup({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    required this.children,
    this.useCard = true,
    this.padding,
  });

  /// Optional group header title.
  final String? title;

  /// Optional group header subtitle.
  final String? subtitle;

  /// Optional leading icon in header.
  final IconData? icon;

  /// Form fields or widgets inside this group.
  final List<Widget> children;

  /// Whether to wrap the group in an [AppCard] surface. Default true.
  final bool useCard;

  /// Custom padding inside the group.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fieldsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            const SizedBox(height: AppSpacing.itemGap),
        ],
      ],
    );

    if (!useCard) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            _buildHeader(isDark),
            const SizedBox(height: AppSpacing.sm),
          ],
          fieldsColumn,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          _buildHeader(isDark),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppCard(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPaddingH),
          child: fieldsColumn,
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: AppIconSize.sm + 4,
            color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.xs + 2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title!,
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
      ],
    );
  }
}
