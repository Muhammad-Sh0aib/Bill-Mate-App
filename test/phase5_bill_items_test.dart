import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/app/router/route_names.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/bills/domain/bill_amount.dart';
import 'package:bill_mate/features/bills/domain/bill_calculations.dart';
import 'package:bill_mate/features/bills/domain/bill_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> _openNewBill(WidgetTester tester) async {
  AppRouter.reset(initialLocation: RouteNames.newBill);
  await tester.pumpWidget(const ProviderScope(child: BillMateApp()));
  await tester.pumpAndSettle();
}

ProviderContainer _providerContainer(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(BillMateApp)),
    listen: false,
  );
}

Future<void> _scrollToAddItem(WidgetTester tester) async {
  for (
    var attempt = 0;
    attempt < 4 && find.text('Add Item').evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -350));
    await tester.pumpAndSettle();
  }
  await Scrollable.ensureVisible(
    tester.element(find.text('Add Item')),
    alignment: 0.85,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('BillAmount', () {
    test('converts decimal amounts to exact paisa', () {
      expect(BillAmount.parsePaisa('500'), 50000);
      expect(BillAmount.parsePaisa('1500.5'), 150050);
      expect(BillAmount.parsePaisa('2500.50'), 250050);
      expect(BillAmount.parsePaisa('0.00'), 0);
      expect(BillAmount.formatPaisa(150050), 'Rs. 1,500.50');
    });

    test('rejects malformed, negative, excessive precision, and overflow', () {
      expect(BillAmount.parsePaisa(''), isNull);
      expect(BillAmount.parsePaisa('1..2'), isNull);
      expect(BillAmount.parsePaisa('abc'), isNull);
      expect(BillAmount.parsePaisa('-1'), isNull);
      expect(BillAmount.parsePaisa('1.234'), isNull);
      expect(BillAmount.parsePaisa('999999999999999999999999'), isNull);
    });

    test('formats subtotals larger than the JavaScript safe integer range', () {
      final total = BigInt.from(9007199254740991) * BigInt.from(2);
      expect(BillAmount.formatPaisaBigInt(total), startsWith('Rs. '));
      expect(BillAmount.formatPaisaBigInt(total), contains('.82'));
    });

    test('sums multiple maximum supported line amounts without overflow', () {
      final maxLineAmount = BillAmount.parsePaisa('90071992547409.91')!;
      final items = [
        BillItem.empty().copyWith(amountInput: '90071992547409.91'),
        BillItem.empty().copyWith(amountInput: '90071992547409.91'),
      ];

      expect(
        BillCalculations.subtotalInPaisa(items),
        BigInt.from(maxLineAmount) * BigInt.from(2),
      );
    });
  });

  group('Bill item draft state', () {
    test(
      'adds unique items and preserves row data through edits and deletes',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(billDraftProvider.notifier);

        controller.updateCustomerName('Atlas Press');
        final originalDate = container.read(billDraftProvider).billDate;
        final first = controller.addItem();
        final second = controller.addItem();
        expect(first.id, isNot(second.id));
        expect(container.read(billDraftProvider).hasUnsavedChanges, isTrue);

        controller.updateItemDescription(
          first.id,
          'Roller repair & adjustment',
        );
        controller.updateItemAmount(first.id, '2500.50');
        controller.updateItemDescription(second.id, 'Gear replacement');
        controller.updateItemAmount(second.id, '500');

        var draft = container.read(billDraftProvider);
        expect(draft.items.map((item) => item.id), [first.id, second.id]);
        expect(draft.items.first.description, 'Roller repair & adjustment');
        expect(draft.items.last.description, 'Gear replacement');
        expect(draft.subtotalInPaisa, BigInt.from(300050));
        expect(draft.hasIncompleteItems, isFalse);
        expect(draft.customerName, 'Atlas Press');
        expect(draft.billDate, originalDate);

        controller.deleteItem(first.id);
        draft = container.read(billDraftProvider);
        expect(draft.items, hasLength(1));
        expect(draft.items.single.id, second.id);
        expect(draft.items.single.description, 'Gear replacement');
        expect(draft.subtotalInPaisa, BigInt.from(50000));
      },
    );

    test(
      'supports many items and preserves order and amounts after deletion',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(billDraftProvider.notifier);
        final items = List.generate(40, (_) => controller.addItem());

        for (var index = 0; index < items.length; index++) {
          controller.updateItemDescription(
            items[index].id,
            'Workshop service $index / inspection',
          );
          controller.updateItemAmount(items[index].id, '${index + 1}.25');
        }

        expect(items.map((item) => item.id).toSet(), hasLength(items.length));
        controller.deleteItem(items[17].id);

        final draft = container.read(billDraftProvider);
        final remainingIndexes = List.generate(
          items.length,
          (index) => index,
        ).where((index) => index != 17).toList();
        expect(
          draft.items.map((item) => item.id),
          remainingIndexes.map((index) => items[index].id),
        );
        expect(
          draft.items.map((item) => item.description),
          remainingIndexes.map(
            (index) => 'Workshop service $index / inspection',
          ),
        );
        expect(
          draft.items.map((item) => item.amountInput),
          remainingIndexes.map((index) => '${index + 1}.25'),
        );
        expect(
          draft.subtotalInPaisa,
          BigInt.from(
            remainingIndexes.fold(
              0,
              (total, index) => total + (index + 1) * 100 + 25,
            ),
          ),
        );
      },
    );

    test('keeps incomplete input distinct from a valid zero amount', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(billDraftProvider.notifier);
      final item = controller.addItem();
      controller.updateItemDescription(item.id, 'Inspection');
      controller.updateItemAmount(item.id, 'not money');

      expect(container.read(billDraftProvider).hasIncompleteItems, isTrue);
      expect(container.read(billDraftProvider).subtotalInPaisa, BigInt.zero);

      controller.updateItemAmount(item.id, '0');
      expect(container.read(billDraftProvider).hasIncompleteItems, isFalse);
      expect(container.read(billDraftProvider).subtotalInPaisa, BigInt.zero);
    });

    test('item copy updates retain stable identity', () {
      final item = BillItem.empty();
      expect(item.copyWith(description: 'Servicing').id, item.id);
      expect(item.copyWith(amountInput: '75.25').amountInPaisa, 7525);
    });
  });

  group('Bill Items screen', () {
    testWidgets('adds rows, edits values, and updates the subtotal', (
      tester,
    ) async {
      await _openNewBill(tester);

      expect(
        find.text('No items yet. Add a service or repair entry.'),
        findsOneWidget,
      );
      await _scrollToAddItem(tester);
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();
      await _scrollToAddItem(tester);
      await tester.tap(find.text('Add Item'));
      await tester.pumpAndSettle();

      final items = _providerContainer(tester).read(billDraftProvider).items;
      expect(items, hasLength(2));
      await tester.enterText(
        find.byKey(ValueKey('bill-item-description-${items[0].id}')),
        'Machine servicing',
      );
      await tester.enterText(
        find.byKey(ValueKey('bill-item-amount-${items[0].id}')),
        '1250.50',
      );
      await tester.enterText(
        find.byKey(ValueKey('bill-item-description-${items[1].id}')),
        'Roller repair',
      );
      await tester.enterText(
        find.byKey(ValueKey('bill-item-amount-${items[1].id}')),
        '500',
      );
      await tester.pumpAndSettle();

      expect(find.text('Rs. 1,750.50'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('2.'), findsOneWidget);
      expect(
        find.text(
          'Subtotal is provisional until every item description and amount is complete.',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'cancelled deletion preserves data; confirmed deletion renumbers',
      (tester) async {
        await _openNewBill(tester);
        await _scrollToAddItem(tester);
        await tester.tap(find.text('Add Item'));
        await tester.pumpAndSettle();
        await _scrollToAddItem(tester);
        await tester.tap(find.text('Add Item'));
        await tester.pumpAndSettle();

        final items = _providerContainer(tester).read(billDraftProvider).items;
        await tester.enterText(
          find.byKey(ValueKey('bill-item-description-${items[0].id}')),
          'Press maintenance',
        );
        await tester.enterText(
          find.byKey(ValueKey('bill-item-amount-${items[0].id}')),
          '800',
        );
        await tester.enterText(
          find.byKey(ValueKey('bill-item-description-${items[1].id}')),
          'Part replacement',
        );
        await tester.enterText(
          find.byKey(ValueKey('bill-item-amount-${items[1].id}')),
          '200',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byTooltip('Delete item 1'));
        await tester.tap(find.byTooltip('Delete item 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(ValueKey('bill-item-description-${items[0].id}')),
              )
              .controller!
              .text,
          'Press maintenance',
        );

        await tester.ensureVisible(find.byTooltip('Delete item 1'));
        await tester.tap(find.byTooltip('Delete item 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete').last);
        await tester.pumpAndSettle();

        expect(find.text('1.'), findsOneWidget);
        expect(find.text('2.'), findsNothing);
        final remainingItem = _providerContainer(tester)
            .read(billDraftProvider)
            .items
            .single;
        expect(
          tester
              .widget<TextField>(
                find.byKey(
                  ValueKey('bill-item-description-${remainingItem.id}'),
                ),
              )
              .controller!
              .text,
          'Part replacement',
        );
        expect(find.text('Rs. 200.00'), findsOneWidget);
      },
    );

    testWidgets(
      'amount uses decimal keyboard and narrow layout has no overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await _openNewBill(tester);
        await _scrollToAddItem(tester);
        await tester.tap(find.text('Add Item'));
        await tester.pumpAndSettle();

        final item = _providerContainer(tester)
            .read(billDraftProvider)
            .items
            .single;
        final amountField = tester.widget<TextField>(
          find.byKey(ValueKey('bill-item-amount-${item.id}')),
        );
        expect(
          amountField.keyboardType,
          const TextInputType.numberWithOptions(decimal: true),
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
