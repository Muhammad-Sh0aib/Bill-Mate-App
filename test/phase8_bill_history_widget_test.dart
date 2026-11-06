import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/app/router/route_names.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';
import 'package:bill_mate/features/company_settings/domain/company_details.dart';
import 'package:bill_mate/features/bills/application/bill_history_refresh_provider.dart';
import 'package:bill_mate/features/bills/application/bill_repository_provider.dart';
import 'package:bill_mate/features/bills/data/bill_repository.dart';
import 'package:bill_mate/features/bills/domain/bill_discount.dart';
import 'package:bill_mate/features/bills/domain/bill_item.dart';
import 'package:bill_mate/features/bills/domain/bill_totals.dart';

void main() {
  setUp(() {
    AppRouter.reset(initialLocation: RouteNames.history);
  });

  testWidgets(
    'history opens, edits without duplicating, and deletes with confirmation',
    (tester) async {
      const billId = 'phase8-widget-flow-bill';
      final repository = _MemoryBillRepository();
      final initialCount = await repository.countCompletedBills();
      final item = BillItem(
        id: '$billId-item',
        description: 'Press repair',
        amountInput: '100.00',
        discount: const BillDiscount(
          type: DiscountType.fixed,
          fixedInput: '1.00',
        ),
      );
      final totals = const BillTotalsCalculator().calculate(
        items: [item],
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '10',
        ),
      );
      await repository.saveCompletedBill(
        billId: billId,
        customerName: 'Phase Eight Customer',
        billDate: DateTime(2026, 10, 12),
        companyNameSnapshot: 'Snapshot Workshop',
        companyPhoneSnapshot: '0300-2246183',
        companyAddressSnapshot: null,
        items: [item],
        billDiscount: totals.billDiscount,
        totals: totals,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            billRepositoryProvider.overrideWithValue(repository),
            companySettingsProvider.overrideWith(
              (ref) async => const CompanyDetails(
                name: 'Snapshot Workshop',
                phone: '0300-2246183',
              ),
            ),
          ],
          child: const BillMateApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(BillMateApp)),
        listen: false,
      );
      container.read(billHistoryRefreshProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Phase Eight Customer'), findsOneWidget);

      await tester.tap(find.text('Phase Eight Customer'));
      await tester.pumpAndSettle();
      expect(find.text('Snapshot Workshop'), findsOneWidget);
      expect(find.text('Press repair'), findsOneWidget);
      expect(find.text('Final payable'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Export / Print / Share'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      expect(find.text('Export / Print / Share'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Preview Bill'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.tap(find.text('Preview Bill'));
      await tester.pumpAndSettle();
      expect(find.text('Bill Preview'), findsOneWidget);
      expect(find.text('Press repair'), findsOneWidget);
      await tester.tap(find.text('Export / Save / Share'));
      await tester.pumpAndSettle();
      expect(find.text('Save PDF to device'), findsOneWidget);
      expect(find.text('Share page-by-page JPGs'), findsOneWidget);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Bill Details'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.dragUntilVisible(
        find.text('Edit Saved Bill'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.tap(find.text('Edit Saved Bill'));
      await tester.pumpAndSettle();
      expect(find.text('Edit Saved Bill'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller
            ?.text,
        'Phase Eight Customer',
      );
      final customerField = find.byType(TextFormField).first;
      await tester.enterText(customerField, 'Updated Phase Eight Customer');
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Update Bill'),
        find.byType(ListView).first,
        const Offset(0, -300),
      );
      await tester.tap(find.text('Update Bill'));
      await tester.pumpAndSettle();

      expect(find.text('Bill Preview'), findsOneWidget);
      expect(find.text('Updated Phase Eight Customer'), findsOneWidget);
      final postEdit = (
        count: await repository.countCompletedBills(),
        bill: await repository.loadById(billId),
      );
      expect(postEdit.count, initialCount + 1);
      final updated = postEdit.bill;
      expect(updated?.items.single.description, 'Press repair');
      expect(updated?.items.single.amountInput, '100.00');
      expect(updated?.billDiscount.percentageInput, '10');

      AppRouter.router.goNamed(RouteNames.historyName);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Updated Phase Eight Customer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete bill'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this bill?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await repository.loadById(billId), isNotNull);

      await tester.tap(find.byTooltip('Delete bill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Bill').last);
      await tester.pumpAndSettle();
      final postDelete = (
        bill: await repository.loadById(billId),
        count: await repository.countCompletedBills(),
      );
      expect(postDelete.bill, isNull);
      expect(postDelete.count, initialCount);
      expect(find.text('Updated Phase Eight Customer'), findsNothing);
    },
  );

  testWidgets('new bill editor saves a valid bill to history', (tester) async {
    AppRouter.reset(initialLocation: RouteNames.newBill);
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = _MemoryBillRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(repository),
          companySettingsProvider.overrideWith(
            (ref) async =>
                const CompanyDetails(name: 'Workshop', phone: '0300-2246183'),
          ),
        ],
        child: const BillMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'New Workflow Customer',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Add Item'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Add Item'));
    await tester.pump();
    final descriptionField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == 'Service or repair detail',
    );
    await tester.ensureVisible(descriptionField);
    await tester.enterText(descriptionField, 'New repair');
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.hintText == '0.00',
      ),
      '50.00',
    );
    await tester.pump();
    await tester.dragUntilVisible(
      find.text('Save Bill'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save Bill'));
    await tester.pumpAndSettle();
    expect(find.text('New Workflow Customer'), findsOneWidget);
    expect(await repository.countCompletedBills(), 1);
    final bill = await repository.searchBills('New Workflow Customer');
    expect(bill.single.items.single.description, 'New repair');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      isEmpty,
    );
    expect(
      find.text('No items yet. Add a service or repair entry.'),
      findsOneWidget,
    );
    expect(find.text('Save Bill'), findsOneWidget);
  });

  testWidgets('preview draft back returns to the bill editor', (tester) async {
    AppRouter.reset(initialLocation: RouteNames.newBill);
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(_MemoryBillRepository()),
          companySettingsProvider.overrideWith(
            (ref) async =>
                const CompanyDetails(name: 'Workshop', phone: '0300-2246183'),
          ),
        ],
        child: const BillMateApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('Preview Draft'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.ensureVisible(find.text('Preview Draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview Draft'));
    await tester.pumpAndSettle();

    expect(find.text('Bill Preview'), findsOneWidget);
    expect(find.text('Workshop'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Preview Draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing saved bill preview shows an explicit error', (
    tester,
  ) async {
    AppRouter.reset(
      initialLocation: '${RouteNames.billPreview}?billId=missing',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          billRepositoryProvider.overrideWithValue(_MemoryBillRepository()),
          companySettingsProvider.overrideWith(
            (ref) async =>
                const CompanyDetails(name: 'Workshop', phone: '0300-2246183'),
          ),
        ],
        child: const BillMateApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This bill could not be found in local storage.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _MemoryBillRepository extends BillRepository {
  final List<BillRecord> _bills = [];

  @override
  Future<void> saveCompletedBill({
    required String billId,
    required String customerName,
    required DateTime billDate,
    required String companyNameSnapshot,
    required String companyPhoneSnapshot,
    required String? companyAddressSnapshot,
    required List<BillItem> items,
    required BillDiscount billDiscount,
    required BillTotals totals,
    String? billNumber,
    int previousRemainingPaisa = 0,
    int advancePaymentPaisa = 0,
  }) async {
    final oldBill = _bills.where((bill) => bill.id == billId).firstOrNull;
    final now = DateTime.now();
    final record = BillRecord(
      id: billId,
      billNumber: billNumber ?? oldBill?.billNumber,
      customerName: customerName,
      billDate: billDate,
      companyNameSnapshot: companyNameSnapshot,
      companyPhoneSnapshot: companyPhoneSnapshot,
      companyAddressSnapshot: companyAddressSnapshot,
      originalSubtotalInPaisa: totals.originalSubtotalInPaisa,
      totalItemDiscountInPaisa: totals.totalItemDiscountInPaisa,
      subtotalAfterItemDiscountsInPaisa:
          totals.subtotalAfterItemDiscountsInPaisa,
      billDiscount: billDiscount,
      billDiscountAmountInPaisa: totals.billDiscountInPaisa,
      finalPayableInPaisa: totals.finalPayableInPaisa,
      previousRemainingInPaisa: totals.previousRemainingInPaisa,
      advancePaymentInPaisa: totals.advancePaymentInPaisa,
      createdAt: oldBill?.createdAt ?? now,
      updatedAt: now,
      items: List.unmodifiable(items),
    );
    if (oldBill == null) {
      _bills.add(record);
    } else {
      _bills[_bills.indexOf(oldBill)] = record;
    }
  }

  @override
  Future<List<BillRecord>> listRecentBills({int limit = 7}) async {
    final sorted = [..._bills]
      ..sort((first, second) {
        final byCreation = second.createdAt.compareTo(first.createdAt);
        return byCreation == 0 ? second.id.compareTo(first.id) : byCreation;
      });
    return sorted.take(limit).toList();
  }

  @override
  Future<int> countCompletedBills() async => _bills.length;

  @override
  Future<List<BillRecord>> searchBills(String query) async {
    final normalized = query.toLowerCase();
    return _bills
        .where(
          (bill) =>
              bill.customerName.toLowerCase().contains(normalized) ||
              bill.id.toLowerCase().contains(normalized) ||
              (bill.billNumber?.toLowerCase().contains(normalized) ?? false),
        )
        .toList();
  }

  @override
  Future<BillRecord?> loadById(String billId) async {
    for (final bill in _bills) {
      if (bill.id == billId) return bill;
    }
    return null;
  }

  @override
  Future<bool> deleteBill(String billId) async {
    final initialLength = _bills.length;
    _bills.removeWhere((bill) => bill.id == billId);
    return _bills.length != initialLength;
  }
}
