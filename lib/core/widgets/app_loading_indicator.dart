import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

/// Lightweight loading indicator for asynchronous operations.
///
/// Use [AppLoadingIndicator.centered] for full-container async operations
/// with an optional message, and [AppLoadingIndicator.inline] for compact
/// inline indicators.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator.centered({super.key, this.message})
    : _centered = true;

  const AppLoadingIndicator.inline({super.key})
    : _centered = false,
      message = null;

  final bool _centered;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indicator = CircularProgressIndicator(
      strokeWidth: _centered ? 3 : 2,
      color: AppColors.accent,
    );

    if (_centered) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              if (message != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  message!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? const Color(0xFF9BB3C6)
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(width: 20, height: 20, child: indicator);
  }
}
