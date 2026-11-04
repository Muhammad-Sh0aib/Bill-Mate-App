import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Shows a standard, accessible confirmation dialog.
///
/// Returns `true` if confirmed, `false` or `null` if cancelled.
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      isDestructive: isDestructive,
      icon: icon,
    ),
  );
}

/// Reusable confirmation dialog widget.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveIcon =
        icon ??
        (isDestructive
            ? Icons.delete_outline_rounded
            : Icons.help_outline_rounded);
    final iconColor = isDestructive
        ? AppColors.error
        : (isDark ? const Color(0xFF90CAF9) : AppColors.primary);

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(effectiveIcon, color: iconColor, size: AppIconSize.md + 2),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.headingSmall.copyWith(
                color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? const Color(0xFF9BB3C6) : AppColors.textSecondary,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.error : AppColors.accent,
            foregroundColor: AppColors.textOnAccent,
            minimumSize: const Size(88, AppSpacing.touchTargetSm),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
