import '../../company_settings/domain/company_details.dart';
import 'bill_calculations.dart';
import 'bill_discount.dart';
import 'bill_item.dart';

class CompanyInfoSnapshot {
  const CompanyInfoSnapshot({required this.name, required this.phone});

  factory CompanyInfoSnapshot.fromSettings(CompanyDetails details) {
    return CompanyInfoSnapshot(name: details.name, phone: details.phone);
  }

  final String name;
  final String phone;
}

class BillDraft {
  BillDraft({
    required this.id,
    required this.customerName,
    required this.billDate,
    required this.companySnapshot,
    required this.createdAt,
    required this.hasUnsavedChanges,
    this.billDiscount = const BillDiscount(),
    List<BillItem> items = const [],
  }) : items = List.unmodifiable(items);

  final String id;
  final String customerName;
  final DateTime billDate;
  final CompanyInfoSnapshot companySnapshot;
  final DateTime createdAt;
  final bool hasUnsavedChanges;
  final BillDiscount billDiscount;
  final List<BillItem> items;

  BigInt get subtotalInPaisa => BillCalculations.subtotalInPaisa(items);

  bool get hasIncompleteItems => BillCalculations.hasIncompleteItems(items);

  BillDraft copyWith({
    String? customerName,
    DateTime? billDate,
    CompanyInfoSnapshot? companySnapshot,
    bool? hasUnsavedChanges,
    BillDiscount? billDiscount,
    List<BillItem>? items,
  }) {
    return BillDraft(
      id: id,
      customerName: customerName ?? this.customerName,
      billDate: billDate ?? this.billDate,
      companySnapshot: companySnapshot ?? this.companySnapshot,
      createdAt: createdAt,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      billDiscount: billDiscount ?? this.billDiscount,
      items: items ?? this.items,
    );
  }
}
