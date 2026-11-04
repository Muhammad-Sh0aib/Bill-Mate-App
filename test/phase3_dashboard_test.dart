import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/features/home/presentation/home_screen.dart';
import 'package:bill_mate/features/home/presentation/widgets/home_header.dart';
import 'package:bill_mate/features/home/presentation/widgets/workshop_identity_card.dart';
import 'package:bill_mate/features/home/presentation/widgets/dashboard_primary_actions.dart';
import 'package:bill_mate/features/home/presentation/widgets/dashboard_quick_access.dart';
import 'package:bill_mate/features/home/presentation/widgets/recent_bills_empty_card.dart';
import 'package:bill_mate/features/home/presentation/widgets/workshop_status_strip.dart';
import 'package:bill_mate/features/bills/application/bill_repository_provider.dart';

import 'support/in_memory_repositories.dart';

Widget _buildTestApp({ThemeMode themeMode = ThemeMode.system}) {
  return ProviderScope(
    overrides: [
      billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
    ],
    child: BillMateApp(themeMode: themeMode),
  );
}

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 3 — Home Dashboard UI & Structure', () {
    testWidgets('Dashboard renders all core sections', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
      await tester.pumpAndSettle();

      // 1. Header with branding
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.text(AppConfig.appName), findsWidgets);
      expect(find.text(AppConfig.appTagline), findsOneWidget);

      // 2. Operational status strip
      expect(find.byType(WorkshopStatusStrip), findsOneWidget);
      expect(find.text('Offline Ready'), findsOneWidget);
      expect(
        find.text(
          'Currency: ${AppConfig.currencyCode} (${AppConfig.currencySymbol})',
        ),
        findsOneWidget,
      );

      // 3. Workshop identity section
      expect(find.byType(WorkshopIdentityCard), findsOneWidget);
      expect(find.text(AppConfig.defaultCompanyName), findsOneWidget);
      expect(find.text(AppConfig.defaultCompanyPhone), findsOneWidget);
      expect(find.text('Offset Printing Press Machinery'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // 4. Primary actions
      expect(find.byType(DashboardPrimaryActions), findsOneWidget);
      expect(find.text('Create New Bill'), findsWidgets);
      expect(find.text('Previous Bills'), findsOneWidget);

      // 5. Quick access section
      expect(find.byType(DashboardQuickAccess), findsOneWidget);
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Bill History'), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);

      // 6. Recent bills honest empty state
      expect(find.byType(RecentBillsEmptyCard), findsOneWidget);
      expect(find.text('Recent Bills'), findsOneWidget);
      expect(find.text('No bills yet'), findsOneWidget);
    });

    testWidgets('Primary Create New Bill action navigates to New Bill screen', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
      await tester.pumpAndSettle();

      // Tap the primary action button in DashboardPrimaryActions
      await tester.tap(
        find.descendant(
          of: find.byType(DashboardPrimaryActions),
          matching: find.text('Create New Bill'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Details'), findsOneWidget);
    });

    testWidgets('Secondary Previous Bills action navigates to History screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(DashboardPrimaryActions),
          matching: find.text('Previous Bills'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bills saved yet'), findsOneWidget);
    });

    testWidgets('Quick access Bill History navigates to History screen', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bill History'));
      await tester.pumpAndSettle();

      expect(find.text('No bills saved yet'), findsOneWidget);
    });

    testWidgets('Workshop identity card tap navigates to Settings screen', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(WorkshopIdentityCard));
      await tester.pumpAndSettle();

      // Workshop Information is a visible section header on the settings screen.
      expect(find.text('Workshop Information'), findsOneWidget);

      // Application Information may require scrolling to be visible —
      // scroll the settings ListView to reveal it, then assert.
      await tester.dragUntilVisible(
        find.text('Application Information'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Application Information'), findsOneWidget);
    });

    testWidgets('Header settings button navigates to Settings screen', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(HomeHeader),
          matching: find.byIcon(Icons.settings_outlined),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Workshop Information'), findsOneWidget);
    });

    testWidgets('Recent bills empty state CTA triggers New Bill navigation', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
      await tester.pumpAndSettle();

      final createBillAction = find.descendant(
        of: find.byType(RecentBillsEmptyCard),
        matching: find.text('Create New Bill'),
      );
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(createBillAction);
      await tester.pumpAndSettle();

      expect(find.text('Customer Details'), findsOneWidget);
    });

    testWidgets('Dark mode renders dashboard cleanly without exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: BillMateApp(themeMode: ThemeMode.dark)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text(AppConfig.appName), findsWidgets);
      expect(find.text(AppConfig.defaultCompanyName), findsOneWidget);
    });

    testWidgets(
      'Narrow 320dp screen width renders without RenderFlex overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3.0;

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text(AppConfig.appName), findsWidgets);
      },
    );
  });
}
