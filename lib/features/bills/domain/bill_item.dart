import 'bill_amount.dart';
import 'bill_discount.dart';

class BillItem {
  BillItem({
    required this.id,
    required this.description,
    required this.amountInput,
    this.discount = const BillDiscount(),
  });

  factory BillItem.empty() {
    _idSequence++;
    return BillItem(
      id: '${DateTime.now().microsecondsSinceEpoch}-$_idSequence',
      description: '',
      amountInput: '',
      discount: const BillDiscount(),
    );
  }

  static int _idSequence = 0;

  final String id;
  final String description;
  final String amountInput;
  final BillDiscount discount;

  int? get amountInPaisa => BillAmount.parsePaisa(amountInput);

  BillItem copyWith({
    String? description,
    String? amountInput,
    BillDiscount? discount,
  }) {
    return BillItem(
      id: id,
      description: description ?? this.description,
      amountInput: amountInput ?? this.amountInput,
      discount: discount ?? this.discount,
    );
  }
}
