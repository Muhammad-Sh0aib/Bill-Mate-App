import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Button visual variant.
enum AppButtonVariant {
  /// Filled accent/brand button — primary call to action.
  primary,

  /// Outlined button — secondary or low-emphasis alternative.
  outlined,

  /// Text-only button — tertiary or inline action.
  text,

  /// Destructive action button — delete or irreversible actions.
  destructive,
}

/// BillMate standard button component.
///
/// Ensures 48dp minimum touch target height, clear loading indicators,
/// accessible labels, leading/trailing icons, and consistent styling
/// across light and dark themes.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.semanticLabel,
  });

  /// The button text.
  final String label;

  /// Callback when pressed. If null or [loading] is true, the button is disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing icon.
  final IconData? trailingIcon;

  /// Visual variant of the button.
  final AppButtonVariant variant;

  /// Whether to display a loading indicator instead of the label/icons.
  final bool loading;

  /// Whether the button should stretch horizontally to fill the parent width.
  final bool fullWidth;

  /// Accessibility label override.
  final String? semanticLabel;

  bool get _isEnabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget childContent;
    if (loading) {
      final spinnerColor = switch (variant) {
        AppButtonVariant.primary => AppColors.textOnAccent,
        AppButtonVariant.destructive => Colors.white,
        AppButtonVariant.outlined =>
          isDark ? const Color(0xFF90CAF9) : AppColors.primary,
        AppButtonVariant.text =>
          isDark ? const Color(0xFF90CAF9) : AppColors.secondary,
      };

      childContent = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: spinnerColor),
      );
    } else {
      final textWidget = Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

      if (icon != null || trailingIcon != null) {
        childContent = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppIconSize.sm + 4),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(child: textWidget),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(trailingIcon, size: AppIconSize.sm + 4),
            ],
          ],
        );
      } else {
        childContent = textWidget;
      }
    }

    final effectiveOnPressed = _isEnabled ? onPressed : null;

    // Override the theme's minimumSize (Size.fromHeight = Size(∞, 48)) when
    // fullWidth is false, so the button can be embedded in a Row without
    // causing "BoxConstraints forces an infinite width" layout errors.
    final compactStyle = fullWidth
        ? null
        : switch (variant) {
            AppButtonVariant.primary => ElevatedButton.styleFrom(
              minimumSize: const Size(48, AppSpacing.touchTarget),
            ),
            AppButtonVariant.outlined => OutlinedButton.styleFrom(
              minimumSize: const Size(48, AppSpacing.touchTarget),
            ),
            AppButtonVariant.text => TextButton.styleFrom(
              minimumSize: const Size(48, AppSpacing.touchTarget),
            ),
            AppButtonVariant.destructive => ElevatedButton.styleFrom(
              minimumSize: const Size(48, AppSpacing.touchTarget),
            ),
          };

    Widget buttonWidget;
    switch (variant) {
      case AppButtonVariant.primary:
        buttonWidget = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: compactStyle,
          child: childContent,
        );
      case AppButtonVariant.outlined:
        buttonWidget = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: compactStyle,
          child: childContent,
        );
      case AppButtonVariant.text:
        buttonWidget = TextButton(
          onPressed: effectiveOnPressed,
          style: compactStyle,
          child: childContent,
        );
      case AppButtonVariant.destructive:
        buttonWidget = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark
                ? const Color(0xFF3B1F22)
                : const Color(0xFFFFCDD2),
            textStyle: AppTextStyles.buttonLarge,
            minimumSize: fullWidth
                ? null
                : const Size(48, AppSpacing.touchTarget),
          ),
          child: childContent,
        );
    }

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: _isEnabled,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: AppSpacing.touchTarget,
          minWidth: fullWidth ? double.infinity : 48.0,
        ),
        child: fullWidth
            ? SizedBox(width: double.infinity, child: buttonWidget)
            : buttonWidget,
      ),
    );
  }
}
