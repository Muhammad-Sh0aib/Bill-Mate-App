import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../bills/domain/bill_amount.dart';
import '../../bills/domain/bill_discount.dart';
import '../../bills/domain/bill_item.dart';
import '../../bills/domain/bill_totals.dart';
import 'bill_document_data.dart';

class BillPdfService {
  BillPdfService._();

  static final BillPdfService instance = BillPdfService._();
  static Future<_BillFonts>? _fonts;

  Future<Uint8List> generate(
    BillDocumentData bill, {
    required BillPaperSize paperSize,
  }) async {
    final fonts = await (_fonts ??= _loadFonts());
    final totals = bill.totals;
    final compact = paperSize == BillPaperSize.compact;
    final pageFormat = paperSize.pageFormat;
    final margin = compact ? 17.0 : 21.0;
    final bodySize = compact ? 8.5 : 9.0;
    final primary = _pdfColor(AppColors.primary);
    final text = _pdfColor(AppColors.documentTextPrimary);
    const secondary = PdfColors.grey700;
    const border = PdfColors.grey400;
    final headerFill = _pdfColor(AppColors.primaryContainer);
    final success = _pdfColor(AppColors.success);

    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      title: 'BillMate bill',
      author: 'BillMate',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat(pageFormat.width, pageFormat.height),
        margin: pw.EdgeInsets.all(margin),
        maxPages: 200,
        header: (context) => _documentHeader(
          bill,
          context,
          compact: compact,
          primary: primary,
          text: text,
          secondary: secondary,
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 5),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(fontSize: compact ? 7 : 8, color: secondary),
          ),
        ),
        build: (context) => [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(
              vertical: compact ? 8 : 10,
              horizontal: 8,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              border: pw.Border(left: pw.BorderSide(color: primary, width: 2)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _infoBlock(
                    'Customer / Company Name',
                    bill.customerName.trim().isEmpty
                        ? 'Customer'
                        : bill.customerName.trim(),
                    text: text,
                    secondary: secondary,
                    bodySize: bodySize,
                  ),
                ),
                pw.SizedBox(width: 8),
                _infoBlock(
                  'Bill Date',
                  _displayDate(bill.billDate),
                  text: text,
                  secondary: secondary,
                  bodySize: bodySize,
                  alignRight: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: compact ? 10 : 14),
          pw.Table(
            border: const pw.TableBorder(
              top: pw.BorderSide(color: border, width: 0.6),
              bottom: pw.BorderSide(color: border, width: 0.6),
              left: pw.BorderSide(color: border, width: 0.6),
              right: pw.BorderSide(color: border, width: 0.6),
              horizontalInside: pw.BorderSide(color: border, width: 0.4),
              verticalInside: pw.BorderSide(color: border, width: 0.4),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(33),
              1: const pw.FlexColumnWidth(),
              2: const pw.FixedColumnWidth(90),
            },
            children: [
              pw.TableRow(
                repeat: true,
                decoration: pw.BoxDecoration(color: headerFill),
                children: [
                  _tableCell(
                    'S.No',
                    bold: true,
                    fontSize: compact ? 8 : 9,
                    color: primary,
                  ),
                  _tableCell(
                    'Particular / Detail',
                    bold: true,
                    fontSize: compact ? 8 : 9,
                    color: primary,
                  ),
                  _tableCell(
                    'Amount',
                    bold: true,
                    fontSize: compact ? 8 : 9,
                    color: primary,
                    alignRight: true,
                  ),
                ],
              ),
              if (bill.items.isEmpty)
                pw.TableRow(
                  children: [
                    _tableCell('', fontSize: bodySize),
                    _tableCell('No bill items', fontSize: bodySize),
                    _tableCell('', fontSize: bodySize),
                  ],
                ),
              for (var index = 0; index < bill.items.length; index++)
                ..._itemRows(
                  bill.items[index],
                  index,
                  totals.itemTotals[index],
                  fontSize: bodySize,
                  compact: compact,
                  text: text,
                  secondary: secondary,
                  success: success,
                ),
            ],
          ),
          pw.SizedBox(height: compact ? 9 : 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: compact ? pageFormat.width - margin * 2 : 270,
              child: _financialSummary(
                totals,
                bodySize: bodySize,
                compact: compact,
                text: text,
                success: success,
              ),
            ),
          ),
          pw.SizedBox(height: compact ? 16 : 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(
                fontSize: bodySize,
                fontWeight: pw.FontWeight.bold,
                color: secondary,
              ),
            ),
          ),
          pw.SizedBox(height: compact ? 20 : 28),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Authorized Signature',
                style: pw.TextStyle(
                  fontSize: compact ? 7 : 8.5,
                  color: secondary,
                ),
              ),
              pw.Text(
                'Received By / Signature',
                style: pw.TextStyle(
                  fontSize: compact ? 7 : 8.5,
                  color: secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<_BillFonts> _loadFonts() async {
    final regularData = await rootBundle.load(
      'assets/fonts/Roboto-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return _BillFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }

  pw.Widget _documentHeader(
    BillDocumentData bill,
    pw.Context context, {
    required bool compact,
    required PdfColor primary,
    required PdfColor text,
    required PdfColor secondary,
  }) {
    final companyName = bill.companyName.trim();
    final companyPhone = bill.companyPhone.trim();
    final address = bill.companyAddress?.trim();
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 9),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.7),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: compact ? 15 : 19,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                  ),
                ),
                if (companyPhone.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      companyPhone,
                      style: pw.TextStyle(
                        fontSize: compact ? 8 : 9,
                        color: secondary,
                      ),
                    ),
                  ),
                if (address != null && address.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1),
                    child: pw.Text(
                      address,
                      style: pw.TextStyle(
                        fontSize: compact ? 7 : 8,
                        color: secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'BILL / INVOICE',
                style: pw.TextStyle(
                  fontSize: compact ? 11 : 14,
                  fontWeight: pw.FontWeight.bold,
                  color: text,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                _displayDate(bill.billDate),
                style: pw.TextStyle(
                  fontSize: compact ? 8 : 9,
                  color: secondary,
                ),
              ),
              if (bill.billNumber?.trim().isNotEmpty == true)
                pw.Text(
                  'Bill No: ${bill.billNumber!.trim()}',
                  style: pw.TextStyle(
                    fontSize: compact ? 7 : 8,
                    color: secondary,
                  ),
                ),
              if (context.pageNumber > 1)
                pw.Text(
                  'Continued',
                  style: pw.TextStyle(
                    fontSize: compact ? 7 : 8,
                    color: secondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<pw.TableRow> _itemRows(
    BillItem item,
    int itemIndex,
    BillItemTotals itemTotals, {
    required double fontSize,
    required bool compact,
    required PdfColor text,
    required PdfColor secondary,
    required PdfColor success,
  }) {
    final description = item.description.trim().isEmpty
        ? 'Item ${itemIndex + 1}'
        : item.description.trim();
    final parts = _splitDescription(description, compact ? 110 : 150);
    final discount = itemTotals.discountAmountInPaisa;
    return [
      for (var partIndex = 0; partIndex < parts.length; partIndex++)
        pw.TableRow(
          children: [
            _tableCell(
              partIndex == 0 ? '${itemIndex + 1}' : '',
              fontSize: fontSize,
              color: text,
            ),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: compact ? 4 : 6,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    parts[partIndex],
                    style: pw.TextStyle(fontSize: fontSize, color: text),
                  ),
                  if (partIndex == parts.length - 1 &&
                      discount > BigInt.zero) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Item Discount: -${BillAmount.formatPaisaBigInt(discount)}',
                      style: pw.TextStyle(
                        fontSize: compact ? 7 : 8,
                        color: success,
                      ),
                    ),
                    pw.Text(
                      'Net Item Amount: ${BillAmount.formatPaisaBigInt(itemTotals.netAmountInPaisa)}',
                      style: pw.TextStyle(
                        fontSize: compact ? 7 : 8,
                        fontWeight: pw.FontWeight.bold,
                        color: text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _tableCell(
              partIndex == 0
                  ? BillAmount.formatPaisaBigInt(
                      itemTotals.originalAmountInPaisa,
                    )
                  : '',
              fontSize: fontSize,
              bold: partIndex == 0,
              alignRight: true,
              color: text,
            ),
          ],
        ),
    ];
  }

  pw.Widget _financialSummary(
    BillTotals totals, {
    required double bodySize,
    required bool compact,
    required PdfColor text,
    required PdfColor success,
  }) {
    final rows = <(String, String, bool)>[
      (
        'Original Subtotal',
        BillAmount.formatPaisaBigInt(totals.originalSubtotalInPaisa),
        false,
      ),
      if (totals.totalItemDiscountInPaisa > BigInt.zero)
        (
          'Item Discounts',
          '-${BillAmount.formatPaisaBigInt(totals.totalItemDiscountInPaisa)}',
          true,
        ),
      (
        'Subtotal After Discounts',
        BillAmount.formatPaisaBigInt(totals.subtotalAfterItemDiscountsInPaisa),
        false,
      ),
      if (totals.billDiscountInPaisa > BigInt.zero)
        (
          _billDiscountLabel(totals.billDiscount),
          '-${BillAmount.formatPaisaBigInt(totals.billDiscountInPaisa)}',
          true,
        ),
    ];

    return pw.Column(
      children: [
        for (final (label, value, isNegative) in rows)
          _summaryRow(
            label,
            value,
            fontSize: bodySize,
            text: text,
            valueColor: isNegative ? success : text,
          ),
        pw.Divider(color: PdfColors.grey400, height: compact ? 12 : 16),
        _summaryRow(
          'FINAL PAYABLE',
          BillAmount.formatPaisaBigInt(totals.finalPayableInPaisa),
          fontSize: bodySize + 2,
          text: text,
          valueColor: text,
          bold: true,
        ),
      ],
    );
  }

  pw.Widget _summaryRow(
    String label,
    String value, {
    required double fontSize,
    required PdfColor text,
    required PdfColor valueColor,
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: text,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 6),
          pw.Text(
            value,
            textAlign: pw.TextAlign.right,
            style: style.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoBlock(
    String title,
    String value, {
    required PdfColor text,
    required PdfColor secondary,
    required double bodySize,
    bool alignRight = false,
  }) {
    return pw.Column(
      crossAxisAlignment: alignRight
          ? pw.CrossAxisAlignment.end
          : pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: bodySize - 2, color: secondary),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: bodySize + 1,
            fontWeight: pw.FontWeight.bold,
            color: text,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String value, {
    required double fontSize,
    bool bold = false,
    bool alignRight = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  List<String> _splitDescription(String description, int maxRunes) {
    final segments = <String>[];
    final runes = description.runes.toList();
    var start = 0;
    while (start < runes.length) {
      var end = start + maxRunes;
      if (end > runes.length) end = runes.length;
      if (end < runes.length) {
        final minimumBreak = start + maxRunes ~/ 2;
        for (var index = end - 1; index >= minimumBreak; index--) {
          if (runes[index] == 32 || runes[index] == 10) {
            end = index;
            break;
          }
        }
      }
      final segment = String.fromCharCodes(runes.sublist(start, end)).trim();
      if (segment.isNotEmpty) segments.add(segment);
      start = end;
      while (start < runes.length &&
          (runes[start] == 32 || runes[start] == 10)) {
        start++;
      }
    }
    return segments.isEmpty ? [''] : segments;
  }

  String _billDiscountLabel(BillDiscount discount) {
    if (discount.type == DiscountType.percentage) {
      return 'Overall Discount (${discount.percentageInput.trim()}%)';
    }
    return 'Overall Discount';
  }

  String _displayDate(DateTime date) => BillDateUtils.formatBillDate(date);

  PdfColor _pdfColor(Color color) => PdfColor(color.r, color.g, color.b);
}

class _BillFonts {
  const _BillFonts({required this.regular, required this.bold});

  final pw.Font regular;
  final pw.Font bold;
}
