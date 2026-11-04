import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/app/router/route_names.dart';
import 'package:bill_mate/core/utils/date_utils.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/bills/domain/bill_draft.dart';
import 'package:bill_mate/features/company_settings/data/company_settings_repository.dart';
import 'package:bill_mate/features/company_settings/domain/company_details.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openNewBill(
  WidgetTester tester, {
  CompanySettingsRepository? companySettingsRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (companySettingsRepository != null)
          companySettingsRepositoryProvider.overrideWithValue(
            companySettingsRepository,
          ),
      ],
      child: const BillMateApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create New Bill').first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('Bill draft state', () {
    test('uses an injected local date and rejects future dates', () {
      final today = DateTime(2026, 10, 25);
      final container = ProviderContainer(
        overrides: [
          billTodayProvider.overrideWith(
            (ref) =>
                () => today,
          ),
        ],
      );
      addTearDown(container.dispose);

      final initialDraft = container.read(billDraftProvider);
      expect(initialDraft.billDate, today);
      expect(initialDraft.companySnapshot.name, AppConfig.defaultCompanyName);
      expect(
        container
            .read(billDraftProvider.notifier)
            .updateBillDate(DateTime(2026, 10, 26)),
        isFalse,
      );
      expect(
        container
            .read(billDraftProvider.notifier)
            .updateBillDate(DateTime(1998, 4, 12)),
        isTrue,
      );
      expect(container.read(billDraftProvider).billDate, DateTime(1998, 4, 12));
    });

    test(
      'refreshes today for an untouched draft but preserves an edited date',
      () {
        var today = DateTime(2026, 10, 25);
        final container = ProviderContainer(
          overrides: [
            billTodayProvider.overrideWith(
              (ref) =>
                  () => today,
            ),
          ],
        );
        addTearDown(container.dispose);

        final controller = container.read(billDraftProvider.notifier);
        today = DateTime(2026, 10, 26);
        controller.refreshDateIfUntouched();
        expect(container.read(billDraftProvider).billDate, today);

        controller.updateBillDate(DateTime(2026, 10, 20));
        today = DateTime(2026, 10, 27);
        controller.refreshDateIfUntouched();
        expect(
          container.read(billDraftProvider).billDate,
          DateTime(2026, 10, 20),
        );
      },
    );

    test('company snapshot remains separate from global settings values', () {
      const settings = CompanyDetails(name: 'Changed Workshop', phone: '123');
      final snapshot = CompanyInfoSnapshot.fromSettings(settings);

      expect(snapshot.name, settings.name);
      expect(snapshot.phone, settings.phone);
      expect(settings.name, isNot(AppConfig.defaultCompanyName));
    });

    test(
      'company settings repository persists and reloads local values',
      () async {
        const details = CompanyDetails(
          name: 'Press Service Co.',
          phone: '555-0100',
        );
        final repository = SharedPreferencesCompanySettingsRepository();

        await repository.save(details);

        expect(await repository.load(), details);
      },
    );
  });

  group('New bill screen', () {
    testWidgets('opens from Home and shows current workshop defaults', (
      tester,
    ) async {
      await _openNewBill(tester);

      expect(find.text('Customer Details'), findsOneWidget);
      expect(find.text('Bill Items'), findsOneWidget);
      expect(
        find.text('No items yet. Add a service or repair entry.'),
        findsOneWidget,
      );
      expect(find.text(AppConfig.defaultCompanyName), findsOneWidget);
      expect(find.text(AppConfig.defaultCompanyPhone), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Save Bill'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      expect(find.text('Save Bill'), findsOneWidget);
      expect(find.text('Export'), findsNothing);
    });

    testWidgets('requires a nonblank customer and accepts punctuation', (
      tester,
    ) async {
      await _openNewBill(tester);
      final customerField = find.byType(TextFormField).first;
      await tester.ensureVisible(customerField);
      await tester.tap(customerField);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Enter a customer or company name.'), findsOneWidget);

      await tester.enterText(customerField, '   ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Enter a customer or company name.'), findsOneWidget);

      await tester.enterText(customerField, '  A&B Press (Pvt.) Ltd.  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Enter a customer or company name.'), findsNothing);
      expect(find.text('A&B Press (Pvt.) Ltd.'), findsOneWidget);
    });

    testWidgets('starts with today and accepts a historical date', (
      tester,
    ) async {
      await _openNewBill(tester);
      expect(
        find.text(BillDateUtils.formatShortDate(BillDateUtils.today())),
        findsOneWidget,
      );

      await tester.tap(find.byType(TextFormField).last);
      await tester.pumpAndSettle();
      expect(find.text('Select bill date'), findsOneWidget);
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();

      final today = BillDateUtils.today();
      final previousMonthDate = DateTime(today.year, today.month - 1, 18);
      expect(
        find.text(BillDateUtils.formatShortDate(previousMonthDate)),
        findsOneWidget,
      );
    });

    testWidgets('settings save refreshes company data and preserves customer', (
      tester,
    ) async {
      await _openNewBill(
        tester,
        companySettingsRepository: _MemoryCompanySettingsRepository(),
      );
      final customerField = find.byType(TextFormField).first;
      await tester.ensureVisible(customerField);
      await tester.enterText(customerField, 'Atlas Printing');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.ensureVisible(find.byType(TextFormField).last);
      await tester.tap(find.byType(TextFormField).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      final today = BillDateUtils.today();
      final previousMonthDate = DateTime(today.year, today.month - 1, 18);
      final selectedBillDate = BillDateUtils.formatShortDate(previousMonthDate);

      await tester.dragUntilVisible(
        find.text('Edit'),
        find.byType(ListView).first,
        const Offset(0, 300),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Atlas Workshop',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '0300-0000000');
      await tester.dragUntilVisible(
        find.text('Save Company Details'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      final saveButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Save Company Details'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(saveButton.onPressed, isNotNull);
      await tester.tap(find.text('Save Company Details'));
      await tester.pumpAndSettle();
      expect(
        find.text('Company details saved. Go back to update the bill.'),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BillMateApp)),
        listen: false,
      );
      expect(
        container.read(billDraftProvider).companySnapshot.name,
        'Atlas Workshop',
      );

      await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('Atlas Workshop'), findsOneWidget);
      expect(find.text('0300-0000000'), findsOneWidget);
      expect(find.text('Atlas Printing'), findsOneWidget);
      expect(find.text(selectedBillDate), findsOneWidget);
    });

    testWidgets('Keep Editing preserves data and Discard exits the draft', (
      tester,
    ) async {
      await _openNewBill(tester);
      final customerField = find.byType(TextFormField).first;
      await tester.ensureVisible(customerField);
      await tester.enterText(customerField, 'Northside Press');
      await tester.pump();

      await tester.tap(find.byType(NavigationDestination).first);
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Customer Details'), findsOneWidget);
      expect(find.text('Northside Press'), findsOneWidget);

      await tester.tap(find.byType(NavigationDestination).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text(AppConfig.appTagline), findsOneWidget);
      expect(find.text('Discard changes?'), findsNothing);

      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('untouched editor exits without a discard prompt', (
      tester,
    ) async {
      await _openNewBill(tester);
      await tester.tap(find.byType(NavigationDestination).first);
      await tester.pumpAndSettle();

      expect(find.text(AppConfig.appTagline), findsOneWidget);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('system Back asks before discarding a modified draft', (
      tester,
    ) async {
      await _openNewBill(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Workshop Client',
      );
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Workshop Client'), findsOneWidget);
    });

    testWidgets('system Back from company settings returns to the same draft', (
      tester,
    ) async {
      await _openNewBill(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'Workshop Client',
      );
      await tester.pump();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Customer Details'), findsOneWidget);
      expect(find.text('Workshop Client'), findsOneWidget);
    });

    testWidgets('keyboard, narrow layout, and dark theme render cleanly', (
      tester,
    ) async {
      AppRouter.reset(initialLocation: RouteNames.newBill);
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(child: BillMateApp(themeMode: ThemeMode.dark)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Customer Details'), findsOneWidget);
    });
  });
}

class _MemoryCompanySettingsRepository implements CompanySettingsRepository {
  CompanyDetails _details = const CompanyDetails(
    name: AppConfig.defaultCompanyName,
    phone: AppConfig.defaultCompanyPhone,
  );

  @override
  Future<CompanyDetails> load() async => _details;

  @override
  Future<void> save(CompanyDetails details) async {
    _details = details;
  }
}
