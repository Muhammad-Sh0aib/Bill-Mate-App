import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_config.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Compact, branded top app bar header for the Home Dashboard.
///
/// Displays the BillMate logo, title, concise subtitle, and a
/// settings action button while respecting system safe areas.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.primary,
      toolbarHeight: 64,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const _BillMateBrandMark(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppConfig.appName,
                          style: AppTextStyles.appBarTitle.copyWith(
                            fontSize: 20,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          AppConfig.appTagline,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textOnPrimary.withAlpha(200),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: AppColors.textOnPrimary,
                      size: AppIconSize.md,
                    ),
                    tooltip: 'Settings',
                    onPressed: () => context.goNamed(RouteNames.settingsName),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BillMateBrandMark extends StatelessWidget {
  const _BillMateBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BillMate brand logo',
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary.withAlpha(25),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.textOnPrimary.withAlpha(40),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.textOnPrimary,
              size: 22,
            ),
            Positioned(
              bottom: 3,
              right: 3,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textOnPrimary,
                  size: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
