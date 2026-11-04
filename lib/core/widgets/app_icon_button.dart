import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// Variant for [AppIconButton].
enum AppIconButtonVariant {
  /// Standard icon button with transparent background.
  standard,

  /// Tonal icon button with soft background container.
  tonal,

  /// Primary icon button with prominent filled background.
  primary,

  /// Destructive icon button for delete or remove actions.
  destructive,
}

/// Standardized icon button ensuring accessibility, minimum touch target (48dp),
/// tooltips, and consistent styling across themes.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
    this.variant = AppIconButtonVariant.standard,
    this.size = AppIconSize.md,
    this.color,
  });

  /// The icon to display.
  final IconData icon;

  /// Callback when pressed. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Semantic tooltip for accessibility and long-press info.
  final String tooltip;

  /// Visual styling variant.
  final AppIconButtonVariant variant;

  /// Icon size (default is 24dp). Touch target remains >= 48dp.
  final double size;

  /// Custom icon color override.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null;

    Color iconColor;
    Color? backgroundColor;

    if (color != null) {
      iconColor = color!;
    } else {
      switch (variant) {
        case AppIconButtonVariant.standard:
          iconColor = isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary;
          backgroundColor = Colors.transparent;
          break;
        case AppIconButtonVariant.tonal:
          iconColor = isDark ? const Color(0xFF90CAF9) : AppColors.primary;
          backgroundColor = isDark
              ? AppColors.surfaceElevatedDark
              : AppColors.primaryContainer;
          break;
        case AppIconButtonVariant.primary:
          iconColor = AppColors.textOnPrimary;
          backgroundColor = AppColors.primary;
          break;
        case AppIconButtonVariant.destructive:
          iconColor = AppColors.error;
          backgroundColor = isDark
              ? const Color(0xFF3B1F22)
              : AppColors.errorBackground;
          break;
      }
    }

    if (!isEnabled) {
      iconColor = isDark ? const Color(0xFF5D6D7E) : AppColors.textDisabled;
      if (backgroundColor != null && backgroundColor != Colors.transparent) {
        backgroundColor = isDark
            ? const Color(0xFF1C2B3A)
            : const Color(0xFFEAEDF1);
      }
    }

    final buttonWidget = IconButton(
      icon: Icon(icon, size: size, color: iconColor),
      onPressed: onPressed,
      tooltip: tooltip,
      style: backgroundColor != null && backgroundColor != Colors.transparent
          ? IconButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            )
          : null,
    );

    return Semantics(
      label: tooltip,
      button: true,
      enabled: isEnabled,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTarget,
          minHeight: AppSpacing.touchTarget,
        ),
        child: buttonWidget,
      ),
    );
  }
}
