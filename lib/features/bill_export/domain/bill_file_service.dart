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

  Future<ShareResult> shareFiles(List<XFile> files, {required String title}) {
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
    return XFile.fromData(bytes, name: fileName, mimeType: mimeType);
  }
}
