import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// BillMate standard card widget.
///
/// A surface container for grouping related content. Supports an
/// optional header with title and trailing action, customizable padding,
/// theme-adaptive background and border, and optional ink ripple on tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  /// The main content of the card.
  final Widget child;

  /// Optional card title displayed in a header row.
  final String? title;

  /// Optional card subtitle displayed under the title.
  final String? subtitle;

  /// Optional trailing widget in the header row (e.g. icon or badge).
  final Widget? trailing;

  /// Custom padding inside the card.
  final EdgeInsetsGeometry? padding;

  /// Tap callback. If provided, the card shows a Material ink ripple on touch.
  final VoidCallback? onTap;

  /// Custom background color override.
  final Color? color;

  /// Custom border color override.
  final Color? borderColor;

  /// Accessibility semantic label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor =
        borderColor ?? (isDark ? const Color(0xFF2C3E50) : AppColors.border);
    final effectiveColor =
        color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final hasHeader = title != null || trailing != null;

    Widget cardBody = Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPaddingH,
            vertical: AppSpacing.cardPaddingV,
          ),
      child: child,
    );

    if (hasHeader) {
      cardBody = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPaddingH,
              AppSpacing.cardPaddingV,
              AppSpacing.cardPaddingH,
              0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
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
                ?trailing,
              ],
            ),
          ),
          cardBody,
        ],
      );
    }

    Widget content = cardBody;

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: content,
      );
    }

    return Semantics(
      label: semanticLabel ?? title,
      container: true,
      button: onTap != null,
      child: Card(
        color: effectiveColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: effectiveBorderColor, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: content,
      ),
    );
  }
}
