import 'bill_item.dart';

abstract class BillCalculations {
  BillCalculations._();

  static BigInt subtotalInPaisa(Iterable<BillItem> items) {
    return items.fold(
      BigInt.zero,
      (subtotal, item) => item.amountInPaisa == null
          ? subtotal
          : subtotal + BigInt.from(item.amountInPaisa!),
    );
  }

  static bool hasIncompleteItems(Iterable<BillItem> items) {
    return items.any(
      (item) => item.description.trim().isEmpty || item.amountInPaisa == null,
    );
  }
}
