import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';

/// Reusable themed divider with consistent vertical margins and colors.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height = AppSpacing.lg,
    this.thickness = 1.0,
    this.color,
    this.indent,
    this.endIndent,
  });

  final double height;
  final double thickness;
  final Color? color;
  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? (isDark ? const Color(0xFF2C3E50) : AppColors.divider);

    return Divider(
      height: height,
      thickness: thickness,
      color: effectiveColor,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
