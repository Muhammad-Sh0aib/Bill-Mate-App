import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../bills/presentation/new_bill_screen.dart';
import 'widgets/dashboard_primary_actions.dart';
import 'widgets/dashboard_quick_access.dart';
import 'widgets/home_header.dart';
import 'widgets/recent_bills_empty_card.dart';
import 'widgets/workshop_identity_card.dart';
import 'widgets/workshop_status_strip.dart';

/// BillMate Home Dashboard Screen.
///
/// Serves as the primary operational hub for the mechanical workshop.
/// Provides immediate, one-tap access to create bills, browse history,
/// view workshop configuration, and monitor operational readiness.
///
/// Contains no fabricated records, imaginary analytics, or fake metrics.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const HomeHeader(),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.sm,
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const WorkshopStatusStrip(),
                          const SizedBox(height: AppSpacing.sm),
                          const WorkshopIdentityCard(),
                          const SizedBox(height: AppSpacing.sm),
                          DashboardPrimaryActions(
                            onNewBill: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NewBillScreen(),
                                ),
                              );
                            },
                            onHistory: () =>
                                context.goNamed(RouteNames.historyName),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DashboardQuickAccess(
                            onHistory: () =>
                                context.goNamed(RouteNames.historyName),
                            onSettings: () =>
                                context.goNamed(RouteNames.settingsName),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          RecentBillsEmptyCard(
                            onNewBill: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const NewBillScreen(),
                                ),
                              );
                            },
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
