import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Severity level for [AppInlineMessage].
enum AppInlineMessageType { info, success, warning, error }

/// An inline banner component for contextual feedback, announcements,
/// or validation messages.
class AppInlineMessage extends StatelessWidget {
  const AppInlineMessage({
    super.key,
    required this.message,
    this.title,
    this.type = AppInlineMessageType.info,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? title;
  final AppInlineMessageType type;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (
      Color foreground,
      Color bgLight,
      Color bgDark,
      IconData icon,
    ) = switch (type) {
      AppInlineMessageType.info => (
        AppColors.info,
        AppColors.infoBackground,
        const Color(0xFF102838),
        Icons.info_outline_rounded,
      ),
      AppInlineMessageType.success => (
        AppColors.success,
        AppColors.successBackground,
        const Color(0xFF132D19),
        Icons.check_circle_outline_rounded,
      ),
      AppInlineMessageType.warning => (
        AppColors.warning,
        AppColors.warningBackground,
        const Color(0xFF332910),
        Icons.warning_amber_rounded,
      ),
      AppInlineMessageType.error => (
        AppColors.error,
        AppColors.errorBackground,
        const Color(0xFF3B1F22),
        Icons.error_outline_rounded,
      ),
    };

    final effectiveBg = isDark ? bgDark : bgLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: foreground.withAlpha(isDark ? 80 : 120),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFFD4E0EB)
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.buttonMedium.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
