import 'package:pdf/pdf.dart';

import '../../../app/config/app_config.dart';
import '../../bills/data/bill_repository.dart';
import '../../bills/domain/bill_amount.dart';
import '../../bills/domain/bill_discount.dart';
import '../../bills/domain/bill_draft.dart';
import '../../bills/domain/bill_item.dart';
import '../../bills/domain/bill_totals.dart';

enum BillPaperSize {
  a4('A4'),
  a5('A5'),
  compact('Compact');

  const BillPaperSize(this.label);

  final String label;

  PdfPageFormat get pageFormat => switch (this) {
    BillPaperSize.a4 => PdfPageFormat.a4,
    BillPaperSize.a5 => PdfPageFormat.a5,
    BillPaperSize.compact => const PdfPageFormat(315, 510),
  };
}

class BillDocumentData {
  BillDocumentData({
    required this.id,
    required this.customerName,
    required this.billDate,
    required this.companyName,
    required this.companyPhone,
    required this.companyAddress,
    required this.billNumber,
    required List<BillItem> items,
    required this.billDiscount,
    BigInt? previousRemainingInPaisa,
    BigInt? advancePaymentInPaisa,
    this.paymentValidationMessage,
  }) : items = List.unmodifiable(items),
       previousRemainingInPaisa = previousRemainingInPaisa ?? BigInt.zero,
       advancePaymentInPaisa = advancePaymentInPaisa ?? BigInt.zero;

  factory BillDocumentData.fromDraft(BillDraft draft) {
    return BillDocumentData(
      id: draft.id,
      customerName: draft.customerName,
      billDate: draft.billDate,
      companyName: draft.companySnapshot.name.isEmpty
          ? AppConfig.defaultCompanyName
          : draft.companySnapshot.name,
      companyPhone: draft.companySnapshot.phone.isEmpty
          ? AppConfig.defaultCompanyPhone
          : draft.companySnapshot.phone,
      companyAddress: null,
      billNumber: null,
      items: draft.items,
      billDiscount: draft.billDiscount,
      previousRemainingInPaisa: BigInt.from(
        BillAmount.parsePaisa(draft.previousRemainingInput) ?? 0,
      ),
      advancePaymentInPaisa: BigInt.from(
        BillAmount.parsePaisa(draft.advancePaymentInput) ?? 0,
      ),
      paymentValidationMessage:
          (draft.previousRemainingInput.trim().isNotEmpty &&
              BillAmount.parsePaisa(draft.previousRemainingInput) == null)
          ? 'Enter a valid Previous Remaining amount.'
          : (draft.advancePaymentInput.trim().isNotEmpty &&
                BillAmount.parsePaisa(draft.advancePaymentInput) == null)
          ? 'Enter a valid Advance Payment amount.'
          : null,
    );
  }

  factory BillDocumentData.fromRecord(BillRecord bill) {
    return BillDocumentData(
      id: bill.id,
      customerName: bill.customerName,
      billDate: bill.billDate,
      companyName: bill.companyNameSnapshot,
      companyPhone: bill.companyPhoneSnapshot,
      companyAddress: bill.companyAddressSnapshot,
      billNumber: bill.billNumber,
      items: bill.items,
      billDiscount: bill.billDiscount,
      previousRemainingInPaisa: bill.previousRemainingInPaisa,
      advancePaymentInPaisa: bill.advancePaymentInPaisa,
    );
  }

  final String id;
  final String customerName;
  final DateTime billDate;
  final String companyName;
  final String companyPhone;
  final String? companyAddress;
  final String? billNumber;
  final List<BillItem> items;
  final BillDiscount billDiscount;
  final BigInt previousRemainingInPaisa;
  final BigInt advancePaymentInPaisa;
  final String? paymentValidationMessage;

  BillTotals get totals => const BillTotalsCalculator().calculate(
    items: items,
    billDiscount: billDiscount,
    previousRemainingPaisa: previousRemainingInPaisa.toInt(),
    advancePaymentPaisa: advancePaymentInPaisa.toInt(),
  );

  String? get exportValidationMessage {
    if (paymentValidationMessage != null) return paymentValidationMessage;
    if (customerName.trim().isEmpty) {
      return 'Enter a customer name before exporting this bill.';
    }
    if (items.isEmpty) return 'Add at least one item before exporting.';
    final billTotals = totals;
    if (!billTotals.isValid) {
      return billTotals.validationSummary.isNotEmpty
          ? billTotals.validationSummary.first
          : 'Complete all bill details before exporting.';
    }
    return null;
  }

  String fileName({required String extension, int? pageNumber}) {
    final customer = _sanitizeFilePart(customerName, fallback: 'Customer');
    final billNo = billNumber?.trim();
    final idSuffix = _tail(_sanitizeFilePart(id, fallback: 'bill'), 12);
    final date =
        '${billDate.year.toString().padLeft(4, '0')}-'
        '${billDate.month.toString().padLeft(2, '0')}-'
        '${billDate.day.toString().padLeft(2, '0')}';
    final parts = ['BillMate', customer, date];
    if (billNo != null && billNo.isNotEmpty) {
      parts.add(_sanitizeFilePart(billNo, fallback: 'bill'));
    }
    parts.add(idSuffix);
    final pagePart = pageNumber == null
        ? ''
        : '_Page_${pageNumber.toString().padLeft(2, '0')}';
    return '${parts.join('_')}$pagePart.$extension';
  }
}

String _sanitizeFilePart(String value, {required String fallback}) {
  var sanitized = value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^[ ._]+|[ ._]+$'), '');
  if (sanitized.isEmpty ||
      RegExp(
        r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
        caseSensitive: false,
      ).hasMatch(sanitized)) {
    sanitized = fallback;
  }
  final runes = sanitized.runes.take(60).toList();
  return String.fromCharCodes(runes);
}

String _tail(String value, int count) {
  final runes = value.runes.toList();
  return String.fromCharCodes(
    runes.skip(runes.length > count ? runes.length - count : 0),
  );
}
