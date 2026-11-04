import 'bill_amount.dart';

enum DiscountType { none, fixed, percentage }

extension DiscountTypeLabel on DiscountType {
  String get label {
    switch (this) {
      case DiscountType.none:
        return 'No discount';
      case DiscountType.fixed:
        return 'Fixed';
      case DiscountType.percentage:
        return 'Percentage';
    }
  }
}

class BillDiscount {
  const BillDiscount({
    this.type = DiscountType.none,
    this.fixedInput = '',
    this.percentageInput = '',
  });

  final DiscountType type;
  final String fixedInput;
  final String percentageInput;

  static const BillDiscount none = BillDiscount();

  BillDiscount copyWith({
    DiscountType? type,
    String? fixedInput,
    String? percentageInput,
  }) {
    return BillDiscount(
      type: type ?? this.type,
      fixedInput: fixedInput ?? this.fixedInput,
      percentageInput: percentageInput ?? this.percentageInput,
    );
  }

  bool get isNone => type == DiscountType.none;

  int? get fixedPaisa =>
      type == DiscountType.fixed ? BillAmount.parsePaisa(fixedInput) : null;

  int? get percentageBasisPoints {
    if (type != DiscountType.percentage) return null;
    final raw = percentageInput.trim();
    if (raw.isEmpty) return null;
    if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(raw)) return null;
    final parts = raw.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null || whole > 100) return null;
    final fraction = parts.length == 1
        ? 0
        : int.parse(parts[1].padRight(2, '0'));
    final basisPoints = whole * 100 + fraction;
    return basisPoints <= 10000 ? basisPoints : null;
  }

  bool isFixedDiscountValidFor(BigInt amountInPaisa) {
    final fixed = fixedPaisa;
    if (fixed == null || fixed < 0) return false;
    return BigInt.from(fixed) <= amountInPaisa;
  }

  bool isPercentageDiscountValid() {
    return percentageBasisPoints != null;
  }

  bool isValidFor(BigInt amountInPaisa) {
    switch (type) {
      case DiscountType.none:
        return true;
      case DiscountType.fixed:
        return isFixedDiscountValidFor(amountInPaisa);
      case DiscountType.percentage:
        return isPercentageDiscountValid();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is BillDiscount &&
      other.type == type &&
      other.fixedInput == fixedInput &&
      other.percentageInput == percentageInput;

  @override
  int get hashCode => Object.hash(type, fixedInput, percentageInput);
}
