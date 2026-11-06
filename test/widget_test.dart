import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/features/bills/application/bill_repository_provider.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';

import 'support/in_memory_repositories.dart';

void main() {
  group('BillMateApp widget tests', () {
    setUp(() {
      databaseFactory = databaseFactoryFfi;
      AppRouter.reset();
      SharedPreferences.setMockInitialValues({});
    });
    testWidgets('app starts and displays BillMate title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      // The app name should be visible somewhere on the home screen.
      expect(find.text(AppConfig.appName), findsWidgets);
    });

    testWidgets('home screen renders without overflow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      // No overflow exceptions should be thrown during rendering.
      expect(tester.takeException(), isNull);
    });

    testWidgets('home screen shows Create New Bill action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 'Create New Bill' appears in both primary actions and the empty state CTA.
      expect(find.text('Create New Bill'), findsWidgets);
    });

    testWidgets('home screen shows Previous Bills action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Previous Bills'), findsOneWidget);
    });

    testWidgets('home screen shows default company name', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConfig.defaultCompanyName), findsOneWidget);
    });

    testWidgets('home screen shows empty bills state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(EmptyBillRepository()),
            companySettingsRepositoryProvider.overrideWithValue(
              MemoryCompanySettingsRepository(),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bills yet'), findsOneWidget);
    });
  });
}
