import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'main_navigation_shell.dart';
import 'route_error_screen.dart';
import 'route_names.dart';
import '../../features/bills/presentation/bill_preview_screen.dart';
import '../../features/bills/presentation/new_bill_screen.dart';
import '../../features/company_settings/presentation/company_settings_screen.dart';
import '../../features/history/presentation/bill_details_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/voice_entry/smart_voice_entry_screen.dart';

/// Central application navigation configuration for BillMate.
///
/// Uses [StatefulShellRoute.indexedStack] to provide persistent bottom
/// tab navigation across the 4 primary destinations (Home, New Bill,
/// History, Settings) with predictable Android back navigation.
class AppRouter {
  AppRouter._();

  /// Default singleton router for the application.
  static GoRouter router = createRouter();

  /// Resets the default router instance to initial state (useful for tests).
  static void reset({String initialLocation = RouteNames.home}) {
    router = createRouter(initialLocation: initialLocation);
  }

  /// Factory to construct a fresh [GoRouter] instance.
  static GoRouter createRouter({String initialLocation = RouteNames.home}) {
    final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      debugLogDiagnostics: false,
      errorBuilder: (context, state) =>
          RouteErrorScreen(location: state.uri.toString()),
      routes: [
        GoRoute(
          path: RouteNames.root,
          redirect: (context, state) => RouteNames.home,
        ),
        GoRoute(
          path: RouteNames.legacyNewBill,
          redirect: (context, state) => RouteNames.newBill,
        ),
        GoRoute(
          path: RouteNames.billPreview,
          name: RouteNames.billPreviewName,
          pageBuilder: (context, state) => NoTransitionPage(
            child: BillPreviewScreen(
              billId: state.uri.queryParameters['billId'],
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.smartVoiceEntry,
          name: RouteNames.smartVoiceEntryName,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SmartVoiceEntryScreen()),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavigationShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.home,
                  name: RouteNames.homeName,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HomeScreen()),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.newBill,
                  name: RouteNames.newBillName,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: NewBillScreen()),
                  routes: [
                    GoRoute(
                      path: ':billId',
                      name: RouteNames.editSavedBillName,
                      pageBuilder: (context, state) => NoTransitionPage(
                        child: NewBillScreen(
                          billId: state.pathParameters['billId'],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.history,
                  name: RouteNames.historyName,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: HistoryScreen()),
                  routes: [
                    GoRoute(
                      path: ':billId',
                      name: RouteNames.billDetailsName,
                      pageBuilder: (context, state) => NoTransitionPage(
                        child: BillDetailsScreen(
                          billId: state.pathParameters['billId']!,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: RouteNames.settings,
                  name: RouteNames.settingsName,
                  pageBuilder: (context, state) => NoTransitionPage(
                    child: CompanySettingsScreen(
                      returnToBill:
                          state.uri.queryParameters['returnToBill'] == 'true',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
