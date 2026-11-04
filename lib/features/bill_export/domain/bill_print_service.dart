import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class BillPrintService {
  BillPrintService._();

  static final BillPrintService instance = BillPrintService._();

  Future<bool> printPdf({
    required Uint8List bytes,
    required String documentName,
    required PdfPageFormat paperFormat,
  }) {
    return Printing.layoutPdf(
      name: documentName,
      format: paperFormat,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  }
}
