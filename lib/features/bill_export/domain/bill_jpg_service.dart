import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:printing/printing.dart';

import 'bill_document_data.dart';
import 'bill_pdf_service.dart';

class BillJpgPage {
  const BillJpgPage({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}

class BillJpgExportException implements Exception {
  const BillJpgExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BillJpgService {
  BillJpgService({BillPdfService? pdfService})
    : _pdfService = pdfService ?? BillPdfService.instance;

  static const _renderDpi = 144.0;
  static const _maxPages = 30;
  static const _maxFullImagePixels = 24 * 1024 * 1024;
  static const _maxFullImageDimension = 16000;

  final BillPdfService _pdfService;

  Future<BillJpgPage> createFullBillImage(
    BillDocumentData bill, {
    required BillPaperSize paperSize,
  }) async {
    final pages = await _renderPages(bill, paperSize);
    var width = 0;
    var height = 0;

    for (final page in pages) {
      width = width > page.width ? width : page.width;
      height += page.height;
      if (height > _maxFullImageDimension ||
          width * height > _maxFullImagePixels) {
        throw const BillJpgExportException(
          'This bill is too long for one image. Choose page-by-page JPGs or PDF.',
        );
      }
    }

    final combined = image.Image(
      width: width,
      height: height,
      numChannels: 3,
      backgroundColor: image.ColorRgb8(255, 255, 255),
    );
    var offset = 0;
    for (final page in pages) {
      final decodedPage = image.decodeJpg(page.bytes);
      if (decodedPage == null) {
        throw const FormatException('A rendered bill page was not a JPEG.');
      }
      image.compositeImage(combined, decodedPage, dstY: offset);
      offset += decodedPage.height;
    }

    return BillJpgPage(
      bytes: Uint8List.fromList(image.encodeJpg(combined, quality: 90)),
      fileName: bill.fileName(extension: 'jpg'),
    );
  }

  Future<List<BillJpgPage>> createPageImages(
    BillDocumentData bill, {
    required BillPaperSize paperSize,
  }) async {
    final pages = await _renderPages(bill, paperSize);
    return [
      for (var index = 0; index < pages.length; index++)
        BillJpgPage(
          bytes: pages[index].bytes,
          fileName: bill.fileName(extension: 'jpg', pageNumber: index + 1),
        ),
    ];
  }

  Future<List<_RenderedPage>> _renderPages(
    BillDocumentData bill,
    BillPaperSize paperSize,
  ) async {
    final pdfBytes = await _pdfService.generate(bill, paperSize: paperSize);
    final pages = <_RenderedPage>[];
    await for (final raster in Printing.raster(pdfBytes, dpi: _renderDpi)) {
      if (pages.length == _maxPages) {
        throw const BillJpgExportException(
          'This bill has too many pages for JPG export. Export it as a PDF instead.',
        );
      }
      final rendered = image.Image.fromBytes(
        width: raster.width,
        height: raster.height,
        bytes: raster.pixels.buffer,
        bytesOffset: raster.pixels.offsetInBytes,
        numChannels: 4,
      );
      pages.add(
        _RenderedPage(
          width: raster.width,
          height: raster.height,
          bytes: Uint8List.fromList(image.encodeJpg(rendered, quality: 88)),
        ),
      );
    }
    if (pages.isEmpty) {
      throw StateError('The bill renderer did not produce any pages.');
    }
    return pages;
  }
}

class _RenderedPage {
  const _RenderedPage({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}
