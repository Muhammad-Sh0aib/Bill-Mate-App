import 'package:bill_mate/app/bill_mate_app.dart';
import 'package:bill_mate/app/router/app_router.dart';
import 'package:bill_mate/app/router/route_names.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/bills/application/bill_repository_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/features/bills/domain/bill_discount.dart';
import 'package:bill_mate/features/bills/domain/bill_item.dart';
import 'package:bill_mate/features/bills/domain/bill_totals.dart';
import 'package:bill_mate/core/utils/decimal_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';

import 'support/in_memory_repositories.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    AppRouter.reset();
    SharedPreferences.setMockInitialValues({});
  });

  test('decimal formatter preserves cursor and limits precision to two', () {
    final formatter = DecimalInputFormatter();
    const oldValue = TextEditingValue(
      text: '12500.50',
      selection: TextSelection.collapsed(offset: 5),
    );
    final invalid = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(
        text: '12500.501',
        selection: TextSelection.collapsed(offset: 9),
      ),
    );
    expect(invalid, oldValue);

    final edited = formatter.formatEditUpdate(
      oldValue,
      const TextEditingValue(
        text: '120500.50',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    expect(edited.text, '120500.50');
    expect(edited.selection.baseOffset, 3);
  });

  group('BillDiscount', () {
    test('parses percentages precisely and rejects values outside 0-100', () {
      expect(
        const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '12.34',
        ).percentageBasisPoints,
        1234,
      );
      expect(
        const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '100',
        ).percentageBasisPoints,
        10000,
      );
      expect(
        const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '100.01',
        ).percentageBasisPoints,
        isNull,
      );
      expect(
        const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '1.234',
        ).percentageBasisPoints,
        isNull,
      );
    });

    test('compares by value for reliable draft change detection', () {
      expect(
        const BillDiscount(type: DiscountType.fixed, fixedInput: '10.00'),
        const BillDiscount(type: DiscountType.fixed, fixedInput: '10.00'),
      );
    });
  });

  group('BillTotalsCalculator', () {
    const calculator = BillTotalsCalculator();

    test('applies item discounts before bill discount with paisa rounding', () {
      final items = [
        BillItem(
          id: 'fixed',
          description: 'Repair',
          amountInput: '1000',
          discount: const BillDiscount(
            type: DiscountType.fixed,
            fixedInput: '100.25',
          ),
        ),
        BillItem(
          id: 'percentage',
          description: 'Parts',
          amountInput: '500',
          discount: const BillDiscount(
            type: DiscountType.percentage,
            percentageInput: '10',
          ),
        ),
      ];

      final totals = calculator.calculate(
        items: items,
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '5',
        ),
      );

      expect(totals.originalSubtotalInPaisa, BigInt.from(150000));
      expect(totals.itemTotals[0].discountAmountInPaisa, BigInt.from(10025));
      expect(totals.itemTotals[1].discountAmountInPaisa, BigInt.from(5000));
      expect(totals.totalItemDiscountInPaisa, BigInt.from(15025));
      expect(totals.subtotalAfterItemDiscountsInPaisa, BigInt.from(134975));
      expect(totals.billDiscountInPaisa, BigInt.from(6749));
      expect(totals.finalPayableInPaisa, BigInt.from(128226));
      expect(totals.isValid, isTrue);
    });

    test('rejects invalid item and bill discounts without negative totals', () {
      final totals = calculator.calculate(
        items: [
          BillItem(
            id: 'too-large',
            description: 'Service',
            amountInput: '10',
            discount: const BillDiscount(
              type: DiscountType.fixed,
              fixedInput: '11',
            ),
          ),
        ],
        billDiscount: const BillDiscount(
          type: DiscountType.fixed,
          fixedInput: '11',
        ),
      );

      expect(totals.isValid, isFalse);
      expect(
        totals.validationSummary,
        contains('Item 1 discount cannot exceed its amount.'),
      );
      expect(
        totals.validationSummary,
        contains(
          'Bill discount cannot exceed the subtotal after item discounts.',
        ),
      );
      expect(totals.totalItemDiscountInPaisa, BigInt.zero);
      expect(totals.billDiscountInPaisa, BigInt.zero);
      expect(totals.finalPayableInPaisa, BigInt.from(1000));
    });

    test('reports malformed bill discount inputs', () {
      final totals = calculator.calculate(
        items: const [],
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '100.01',
        ),
      );

      expect(totals.isValid, isFalse);
      expect(
        totals.validationSummary,
        contains('Enter a percentage between 0% and 100%.'),
      );
      expect(totals.finalPayableInPaisa, BigInt.zero);
    });

    test('rounds half paisa percentages up', () {
      final totals = calculator.calculate(
        items: [
          BillItem(id: 'odd-paisa', description: 'Part', amountInput: '0.01'),
        ],
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '50',
        ),
      );

      expect(totals.billDiscountInPaisa, BigInt.one);
      expect(totals.finalPayableInPaisa, BigInt.zero);
    });

    test('calculates payment adjustments separately from discounts', () {
      final totals = calculator.calculate(
        items: [
          BillItem(
            id: 'repair',
            description: 'Repair',
            amountInput: '17000',
            discount: const BillDiscount(
              type: DiscountType.fixed,
              fixedInput: '1200',
            ),
          ),
        ],
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '5',
        ),
        previousRemainingPaisa: 200000,
        advancePaymentPaisa: 500000,
      );

      expect(totals.originalSubtotalInPaisa, BigInt.from(1700000));
      expect(totals.totalItemDiscountInPaisa, BigInt.from(120000));
      expect(totals.subtotalAfterItemDiscountsInPaisa, BigInt.from(1580000));
      expect(totals.billDiscountInPaisa, BigInt.from(79000));
      expect(totals.finalPayableInPaisa, BigInt.from(1501000));
      expect(totals.previousRemainingInPaisa, BigInt.from(200000));
      expect(totals.advancePaymentInPaisa, BigInt.from(500000));
      expect(totals.netAmountDueInPaisa, BigInt.from(1201000));
      expect(totals.isValid, isTrue);
    });

    test('rejects advance payments greater than current bill payable', () {
      final totals = calculator.calculate(
        items: [
          BillItem(id: 'repair', description: 'Repair', amountInput: '100'),
        ],
        billDiscount: const BillDiscount(),
        advancePaymentPaisa: 10001,
      );

      expect(totals.isValid, isFalse);
      expect(
        totals.validationSummary,
        contains('Advance payment cannot exceed the bill payable amount.'),
      );
    });
  });

  test('bill discounts mark an otherwise empty draft as changed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(billDraftProvider.notifier);

    controller.updateBillDiscount(
      const BillDiscount(type: DiscountType.fixed, fixedInput: '25'),
    );

    expect(container.read(billDraftProvider).hasUnsavedChanges, isTrue);
    controller.reset();
    expect(container.read(billDraftProvider).hasUnsavedChanges, isFalse);
  });

  testWidgets('item and bill discount editors render the applied totals', (
    tester,
  ) async {
    AppRouter.reset(initialLocation: RouteNames.newBill);
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
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BillMateApp)),
      listen: false,
    );
    final item = container.read(billDraftProvider).items.single;
    final descriptionField = tester.widget<TextField>(
      find.byKey(ValueKey('bill-item-description-${item.id}')),
    );
    final amountField = tester.widget<TextField>(
      find.byKey(ValueKey('bill-item-amount-${item.id}')),
    );
    expect(descriptionField.textDirection, TextDirection.ltr);
    expect(descriptionField.textAlign, TextAlign.left);
    expect(amountField.textDirection, TextDirection.ltr);

    container.read(billDraftProvider.notifier)
      ..updateItemDescription(item.id, 'Workshop repair')
      ..updateItemAmount(item.id, '1000');
    await tester.pumpAndSettle();

    container.read(billDraftProvider.notifier)
      ..updateItemDiscount(
        item.id,
        const BillDiscount(type: DiscountType.fixed, fixedInput: '100'),
      )
      ..updateBillDiscount(
        const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '10',
        ),
      );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButton<DiscountType>>(
            find.byKey(ValueKey('bill-item-discount-${item.id}-type')),
          )
          .value,
      DiscountType.fixed,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(ValueKey('bill-item-discount-${item.id}-value')),
          )
          .initialValue,
      '100',
    );

    final discountField = find.byKey(const ValueKey('bill-discount-value'));
    await Scrollable.ensureVisible(tester.element(discountField));

    expect(
      container.read(billDraftProvider).billDiscount.percentageBasisPoints,
      1000,
    );
    expect(
      tester
          .widget<DropdownButton<DiscountType>>(
            find.byKey(const ValueKey('bill-discount-type')),
          )
          .value,
      DiscountType.percentage,
    );
    expect(tester.widget<TextFormField>(discountField).initialValue, '10');
    expect(find.text('Rs. 810.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(
      find.text('Payment Details (Optional)'),
      find.byType(ListView).first,
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(const ValueKey('previous-remaining-input')),
              matching: find.byType(EditableText),
            ),
          )
          .textDirection,
      TextDirection.ltr,
    );
  });
}
