import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Standard, consistent app bar for BillMate screens.
///
/// Ensures proper branding, leading back button when [canPop] is true
/// or when forced with [showBackButton], optional subtitle, actions,
/// and safe-area handling without layout overflow.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.showBackButton,
    this.onBack,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  /// The screen title string.
  final String title;

  /// Optional subtitle below the title.
  final String? subtitle;

  /// Custom leading widget override.
  final Widget? leading;

  /// If non-null, explicitly controls whether to show the back button.
  /// If null, automatically shows back button if [context.canPop()] is true.
  final bool? showBackButton;

  /// Custom callback on back press. If null, defaults to [context.pop()].
  final VoidCallback? onBack;

  /// Optional action buttons at the trailing edge.
  final List<Widget>? actions;

  /// Background color override. Defaults to [AppColors.primary].
  final Color? backgroundColor;

  /// Foreground icon and text color override. Defaults to [AppColors.textOnPrimary].
  final Color? foregroundColor;

  /// Optional bottom widget (e.g. tabs or progress bar).
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight +
        (subtitle != null ? 18.0 : 0.0) +
        (bottom?.preferredSize.height ?? 0.0),
  );

  @override
  Widget build(BuildContext context) {
    bool canPop = showBackButton ?? false;
    if (showBackButton == null) {
      try {
        canPop = context.canPop();
      } catch (_) {
        canPop = Navigator.of(context).canPop();
      }
    }
    final effectiveBg = backgroundColor ?? AppColors.primary;
    final effectiveFg = foregroundColor ?? AppColors.textOnPrimary;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && canPop) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        tooltip: 'Back',
        color: effectiveFg,
        onPressed:
            onBack ??
            () {
              try {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
              } catch (_) {}
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
      );
    }

    Widget titleWidget;
    if (subtitle != null) {
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyles.appBarTitle.copyWith(color: effectiveFg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(
              color: effectiveFg.withAlpha(200),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      titleWidget = Text(
        title,
        style: AppTextStyles.appBarTitle.copyWith(color: effectiveFg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return AppBar(
      title: titleWidget,
      leading: leadingWidget,
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppSpacing.xs)]
          : null,
      backgroundColor: effectiveBg,
      foregroundColor: effectiveFg,
      elevation: 0,
      centerTitle: false,
      bottom: bottom,
    );
  }
}
