import 'bill_discount.dart';
import 'bill_item.dart';

class BillItemTotals {
  const BillItemTotals({
    required this.originalAmountInPaisa,
    required this.discountAmountInPaisa,
    required this.netAmountInPaisa,
  });

  final BigInt originalAmountInPaisa;
  final BigInt discountAmountInPaisa;
  final BigInt netAmountInPaisa;
}

class BillTotals {
  const BillTotals({
    required this.originalSubtotalInPaisa,
    required this.totalItemDiscountInPaisa,
    required this.subtotalAfterItemDiscountsInPaisa,
    required this.billDiscountInPaisa,
    required this.finalPayableInPaisa,
    required this.previousRemainingInPaisa,
    required this.advancePaymentInPaisa,
    required this.netAmountDueInPaisa,
    required this.itemTotals,
    required this.isValid,
    required this.validationSummary,
    required this.billDiscount,
  });

  final BigInt originalSubtotalInPaisa;
  final BigInt totalItemDiscountInPaisa;
  final BigInt subtotalAfterItemDiscountsInPaisa;
  final BigInt billDiscountInPaisa;
  final BigInt finalPayableInPaisa;
  final BigInt previousRemainingInPaisa;
  final BigInt advancePaymentInPaisa;
  final BigInt netAmountDueInPaisa;
  final List<BillItemTotals> itemTotals;
  final bool isValid;
  final List<String> validationSummary;
  final BillDiscount billDiscount;
}

class BillTotalsCalculator {
  const BillTotalsCalculator();

  BillTotals calculate({
    required List<BillItem> items,
    required BillDiscount billDiscount,
    int previousRemainingPaisa = 0,
    int advancePaymentPaisa = 0,
  }) {
    final itemTotals = <BillItemTotals>[];
    final validationSummary = <String>[];
    var originalSubtotal = BigInt.zero;
    var totalItemDiscount = BigInt.zero;
    var itemsAreValid = true;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final amount = item.amountInPaisa;
      final amountInPaisa = amount ?? 0;
      final originalAmount = BigInt.from(amountInPaisa);
      originalSubtotal += originalAmount;

      final discountIsValid =
          amount == null || item.discount.isValidFor(originalAmount);
      if (!discountIsValid) {
        itemsAreValid = false;
        validationSummary.add(
          _itemDiscountError(item, index + 1, amountInPaisa),
        );
      }
      if (item.description.trim().isEmpty || amount == null) {
        itemsAreValid = false;
      }

      final itemDiscount = discountIsValid
          ? _discountForItemAmount(item, amountInPaisa)
          : BigInt.zero;
      totalItemDiscount += itemDiscount;

      itemTotals.add(
        BillItemTotals(
          originalAmountInPaisa: originalAmount,
          discountAmountInPaisa: itemDiscount,
          netAmountInPaisa: originalAmount - itemDiscount,
        ),
      );
    }

    final subtotalAfterItemDiscounts = originalSubtotal - totalItemDiscount;
    var finalBillDiscount = BigInt.zero;
    var billDiscountIsValid = true;

    if (billDiscount.type == DiscountType.fixed) {
      final fixed = billDiscount.fixedPaisa;
      if (fixed == null) {
        billDiscountIsValid = false;
        validationSummary.add('Enter a valid non-negative bill discount.');
      } else if (BigInt.from(fixed) > subtotalAfterItemDiscounts) {
        billDiscountIsValid = false;
        validationSummary.add(
          'Bill discount cannot exceed the subtotal after item discounts.',
        );
      } else {
        finalBillDiscount = BigInt.from(fixed);
      }
    } else if (billDiscount.type == DiscountType.percentage) {
      final percent = billDiscount.percentageBasisPoints;
      if (percent == null) {
        billDiscountIsValid = false;
        validationSummary.add('Enter a percentage between 0% and 100%.');
      } else {
        finalBillDiscount = _percentageOf(subtotalAfterItemDiscounts, percent);
      }
    }

    final finalPayable = subtotalAfterItemDiscounts - finalBillDiscount;
    final previousRemaining = BigInt.from(previousRemainingPaisa);
    final advancePayment = BigInt.from(advancePaymentPaisa);
    final netAmountDue = finalPayable + previousRemaining - advancePayment;
    var paymentsAreValid = true;
    if (previousRemaining.isNegative || advancePayment.isNegative) {
      paymentsAreValid = false;
      validationSummary.add('Payment amounts cannot be negative.');
    }
    if (advancePayment > finalPayable) {
      paymentsAreValid = false;
      validationSummary.add(
        'Advance payment cannot exceed the bill payable amount.',
      );
    }

    return BillTotals(
      originalSubtotalInPaisa: originalSubtotal,
      totalItemDiscountInPaisa: totalItemDiscount,
      subtotalAfterItemDiscountsInPaisa: subtotalAfterItemDiscounts,
      billDiscountInPaisa: finalBillDiscount,
      finalPayableInPaisa: finalPayable,
      previousRemainingInPaisa: previousRemaining,
      advancePaymentInPaisa: advancePayment,
      netAmountDueInPaisa: netAmountDue,
      itemTotals: itemTotals,
      isValid:
          itemsAreValid &&
          billDiscountIsValid &&
          paymentsAreValid &&
          validationSummary.isEmpty,
      validationSummary: validationSummary,
      billDiscount: billDiscount,
    );
  }

  BigInt _discountForItemAmount(BillItem item, int originalAmountInPaisa) {
    final discount = item.discount;
    if (discount.type == DiscountType.none) return BigInt.zero;
    if (discount.type == DiscountType.fixed) {
      return BigInt.from(discount.fixedPaisa ?? 0);
    }
    return _percentageOf(
      BigInt.from(originalAmountInPaisa),
      discount.percentageBasisPoints ?? 0,
    );
  }

  String _itemDiscountError(BillItem item, int itemNumber, int amountInPaisa) {
    final discount = item.discount;
    if (discount.type == DiscountType.fixed) {
      if (discount.fixedPaisa == null) {
        return 'Item $itemNumber discount must be a valid non-negative amount.';
      }
      if (!discount.isFixedDiscountValidFor(BigInt.from(amountInPaisa))) {
        return 'Item $itemNumber discount cannot exceed its amount.';
      }
    } else if (discount.type == DiscountType.percentage &&
        !discount.isPercentageDiscountValid()) {
      return 'Item $itemNumber discount must be between 0% and 100%.';
    }
    return 'Item $itemNumber discount is invalid.';
  }

  BigInt _percentageOf(BigInt amount, int basisPoints) {
    if (amount <= BigInt.zero || basisPoints <= 0) return BigInt.zero;
    final numerator = amount * BigInt.from(basisPoints);
    final quotient = numerator ~/ BigInt.from(10000);
    final remainder = numerator % BigInt.from(10000);
    if (remainder * BigInt.two >= BigInt.from(10000)) {
      return quotient + BigInt.one;
    }
    return quotient;
  }
}
