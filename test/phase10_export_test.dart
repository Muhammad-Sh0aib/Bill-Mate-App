import 'dart:convert';

import 'package:bill_mate/features/bill_export/domain/bill_document_data.dart';
import 'package:bill_mate/features/bill_export/domain/bill_pdf_service.dart';
import 'package:bill_mate/features/bills/domain/bill_discount.dart';
import 'package:bill_mate/features/bills/domain/bill_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bill export filenames are safe and page names are unique', () {
    final bill = _sampleBill(
      customerName: 'Customer/Parts: North',
      billNumber: 'INV/24',
    );

    expect(
      bill.fileName(extension: 'pdf'),
      'BillMate_Customer_Parts_North_2026-10-12_INV_24_ll-sample-01.pdf',
    );
    expect(
      bill.fileName(extension: 'jpg', pageNumber: 2),
      'BillMate_Customer_Parts_North_2026-10-12_INV_24_ll-sample-01_Page_02.jpg',
    );
  });

  test(
    'PDF export includes a multi-page bill and uses a real page format',
    () async {
      final bill = _sampleBill(
        items: [
          for (var index = 0; index < 55; index++)
            BillItem(
              id: 'item-$index',
              description:
                  'Offset machine service repair item number $index with '
                  'inspection, parts replacement, calibration, testing, '
                  'and workshop labor included.',
              amountInput: '1200.00',
              discount: const BillDiscount(
                type: DiscountType.fixed,
                fixedInput: '100.00',
              ),
            ),
        ],
        billDiscount: const BillDiscount(
          type: DiscountType.percentage,
          percentageInput: '10',
        ),
      );

      final bytes = await BillPdfService.instance.generate(
        bill,
        paperSize: BillPaperSize.a5,
      );
      final pdfText = latin1.decode(bytes, allowInvalid: true);
      final pageCount = RegExp(r'/Type\s*/Pages[\s\S]{0,100}?/Count\s+(\d+)')
          .firstMatch(pdfText)
          ?.group(1);
      final pageSize = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]',
      ).firstMatch(pdfText);

      expect(latin1.decode(bytes.take(5).toList()), '%PDF-');
      expect(pageCount, isNotNull);
      expect(int.parse(pageCount!), greaterThan(1));
      expect(pageSize, isNotNull);
      expect(double.parse(pageSize!.group(1)!), closeTo(419.53, 0.1));
      expect(double.parse(pageSize.group(2)!), closeTo(595.28, 0.1));
      expect(bill.totals.finalPayableInPaisa, BigInt.from(5_445_000));
    },
  );

  test('invalid drafts cannot be exported', () {
    final bill = _sampleBill(customerName: ' ');
    expect(
      bill.exportValidationMessage,
      'Enter a customer name before exporting this bill.',
    );
  });
}

BillDocumentData _sampleBill({
  String customerName = 'Workshop Customer',
  String? billNumber,
  List<BillItem>? items,
  BillDiscount billDiscount = const BillDiscount(),
}) {
  return BillDocumentData(
    id: 'bill-sample-01',
    customerName: customerName,
    billDate: DateTime(2026, 10, 12),
    companyName: 'Snapshot Workshop',
    companyPhone: '0300-2246183',
    companyAddress: null,
    billNumber: billNumber,
    items:
        items ??
        [
          BillItem(
            id: 'item-1',
            description: 'Press repair',
            amountInput: '1200.00',
            discount: const BillDiscount(
              type: DiscountType.fixed,
              fixedInput: '100.00',
            ),
          ),
        ],
    billDiscount: billDiscount,
  );
}
