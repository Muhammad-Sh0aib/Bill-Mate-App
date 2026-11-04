import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized box shadow tokens for BillMate.
///
/// Keeps elevation shadows subtle and consistent across cards,
/// dialogs, and elevated action surfaces.
abstract class AppShadows {
  AppShadows._();

  /// Subtle elevation shadow for cards and light containers.
  static List<BoxShadow> get low => [
    BoxShadow(
      color: AppColors.primary.withAlpha(12),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  /// Medium shadow for floating cards, dropdowns, and bottom sheets.
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: AppColors.primary.withAlpha(20),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  /// High shadow for modals, dialogs, and floating banners.
  static List<BoxShadow> get high => [
    BoxShadow(
      color: AppColors.primary.withAlpha(35),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  /// Soft card shadow tailored for list cards.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withAlpha(8),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
}
