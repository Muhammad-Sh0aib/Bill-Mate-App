import 'package:flutter/foundation.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';

import 'bill_jpg_service.dart';

class BillFileService {
  BillFileService._();

  static final BillFileService instance = BillFileService._();

  Future<bool> saveFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      final result = await shareFiles([
        _sharedFile(bytes: bytes, fileName: fileName, mimeType: mimeType),
      ], title: 'Save or share bill');
      return result.status == ShareResultStatus.success;
    }

    final savedPath = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: fileName,
        mimeTypesFilter: [mimeType],
        localOnly: true,
      ),
    );
    return savedPath != null;
  }

  Future<bool> savePageImages(List<BillJpgPage> pages) async {
    if (pages.isEmpty) return false;
    if (kIsWeb) {
      final result = await shareFiles([
        for (final page in pages)
          _sharedFile(
            bytes: page.bytes,
            fileName: page.fileName,
            mimeType: 'image/jpeg',
          ),
      ], title: 'Save or share bill pages');
      return result.status == ShareResultStatus.success;
    }

    final directory = await FlutterFileDialog.pickDirectory();
    if (directory == null) return false;
    for (final page in pages) {
      final savedPath = await FlutterFileDialog.saveFileToDirectory(
        directory: directory,
        data: page.bytes,
        fileName: page.fileName,
        mimeType: 'image/jpeg',
      );
      if (savedPath == null) {
        throw StateError('The selected folder did not accept a bill image.');
      }
    }
    return true;
  }

  Future<ShareResult> shareFiles(
    List<XFile> files, {
    required String title,
  }) async {
    if (files.isEmpty) {
      throw ArgumentError.value(
        files,
        'files',
        'At least one file is required.',
      );
    }
    for (final file in files) {
      if (await file.length() == 0) {
        throw StateError('The generated bill file is empty.');
      }
    }
    return SharePlus.instance.share(
      ShareParams(
        files: files,
        fileNameOverrides: [for (final file in files) file.name],
        title: title,
        subject: 'BillMate bill',
        downloadFallbackEnabled: true,
      ),
    );
  }

  Future<ShareResult> shareFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return shareFiles([
      _sharedFile(bytes: bytes, fileName: fileName, mimeType: mimeType),
    ], title: 'Share bill');
  }

  Future<ShareResult> sharePageImages(List<BillJpgPage> pages) {
    return shareFiles([
      for (final page in pages)
        _sharedFile(
          bytes: page.bytes,
          fileName: page.fileName,
          mimeType: 'image/jpeg',
        ),
    ], title: 'Share bill pages');
  }

  XFile _sharedFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    if (bytes.isEmpty) {
      throw StateError('The generated bill file is empty.');
    }
    if (mimeType == 'application/pdf' &&
        !(bytes.length >= 5 &&
            bytes[0] == 0x25 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x44 &&
            bytes[3] == 0x46 &&
            bytes[4] == 0x2d)) {
      throw const FormatException('The generated PDF is invalid.');
    }
    if (mimeType == 'image/jpeg' &&
        !(bytes.length >= 4 &&
            bytes[0] == 0xff &&
            bytes[1] == 0xd8 &&
            bytes[bytes.length - 2] == 0xff &&
            bytes.last == 0xd9)) {
      throw const FormatException('The generated JPEG is invalid.');
    }
    return XFile.fromData(bytes, name: fileName, mimeType: mimeType);
  }
}
