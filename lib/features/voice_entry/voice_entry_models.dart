import '../bills/domain/bill_discount.dart';
import '../bills/domain/bill_item.dart';

class VoiceEntryItemProposal {
  const VoiceEntryItemProposal({
    required this.id,
    required this.description,
    required this.amountInput,
    this.discount = const BillDiscount(),
    this.warning,
  });

  final String id;
  final String description;
  final String amountInput;
  final BillDiscount discount;
  final String? warning;

  BillItem toBillItem() {
    return BillItem(
      id: id,
      description: description,
      amountInput: amountInput,
      discount: discount,
    );
  }
}

class VoiceEntryProposal {
  const VoiceEntryProposal({
    required this.transcript,
    required this.customerName,
    required this.items,
    required this.billDiscount,
    required this.warnings,
    required this.issues,
  });

  final String transcript;
  final String customerName;
  final List<VoiceEntryItemProposal> items;
  final BillDiscount billDiscount;
  final List<String> warnings;
  final List<String> issues;

  bool get hasWarnings => warnings.isNotEmpty;
  bool get isEmpty => customerName.trim().isEmpty && items.isEmpty;
  bool get hasCustomer => customerName.trim().isNotEmpty;

  VoiceEntryProposal copyWith({
    String? transcript,
    String? customerName,
    List<VoiceEntryItemProposal>? items,
    BillDiscount? billDiscount,
    List<String>? warnings,
    List<String>? issues,
  }) {
    return VoiceEntryProposal(
      transcript: transcript ?? this.transcript,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      billDiscount: billDiscount ?? this.billDiscount,
      warnings: warnings ?? this.warnings,
      issues: issues ?? this.issues,
    );
  }
}
