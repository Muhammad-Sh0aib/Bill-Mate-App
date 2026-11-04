import 'package:flutter/material.dart';

import '../../../../app/theme/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';

/// Primary call-to-action buttons on the Home Dashboard.
///
/// Features the prominent "Create New Bill" action as the most obvious
/// interaction on the screen, paired with "Previous Bills" as the secondary action.
class DashboardPrimaryActions extends StatelessWidget {
  const DashboardPrimaryActions({
    super.key,
    required this.onNewBill,
    required this.onHistory,
  });

  /// Navigates to the bill creation screen.
  final VoidCallback onNewBill;

  /// Navigates to the bill history screen.
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Create New Bill',
          icon: Icons.add_circle_outline_rounded,
          onPressed: onNewBill,
          semanticLabel: 'Create New Bill: Start a new bill for this workshop',
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        AppButton(
          label: 'Previous Bills',
          icon: Icons.history_rounded,
          variant: AppButtonVariant.outlined,
          onPressed: onHistory,
          semanticLabel: 'Previous Bills: View and search past workshop bills',
        ),
      ],
    );
  }
}
