import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/bill_document_data.dart';
import '../domain/bill_file_service.dart';
import '../domain/bill_jpg_service.dart';
import '../domain/bill_pdf_service.dart';
import '../domain/bill_print_service.dart';

enum _ExportAction {
  savePdf,
  sharePdf,
  printPdf,
  saveFullJpg,
  shareFullJpg,
  savePageJpgs,
  sharePageJpgs,
}

class BillExportActions extends StatefulWidget {
  const BillExportActions({
    super.key,
    required this.bill,
    required this.paperSize,
    this.buttonLabel = 'Export Bill',
  });

  final BillDocumentData bill;
  final BillPaperSize paperSize;
  final String buttonLabel;

  @override
  State<BillExportActions> createState() => _BillExportActionsState();
}

class _BillExportActionsState extends State<BillExportActions> {
  bool _isBusy = false;
  bool _isSelectingOptions = false;
  String _progressMessage = 'Preparing export...';

  Future<void> _openOptions() async {
    if (_isBusy || _isSelectingOptions) return;
    setState(() => _isSelectingOptions = true);
    final action = await showModalBottomSheet<_ExportAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _ExportOptionsSheet(),
    );
    if (!mounted) return;
    setState(() => _isSelectingOptions = false);
    if (action == null) return;

    final validationMessage = widget.bill.exportValidationMessage;
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() {
      _isBusy = true;
      _progressMessage = _progressFor(action);
    });
    try {
      await _perform(action);
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'bill_export');
      if (mounted) {
        _showMessage(_failureMessage(action, error));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _perform(_ExportAction action) async {
    final bill = widget.bill;
    final paperSize = widget.paperSize;
    final pdfService = BillPdfService.instance;
    final fileService = BillFileService.instance;
    switch (action) {
      case _ExportAction.savePdf:
        final bytes = await pdfService.generate(bill, paperSize: paperSize);
        final saved = await fileService.saveFile(
          bytes: bytes,
          fileName: bill.fileName(extension: 'pdf'),
          mimeType: 'application/pdf',
        );
        if (mounted) {
          _showMessage(saved ? _saveSuccessMessage('PDF') : 'Save cancelled.');
        }
      case _ExportAction.sharePdf:
        final bytes = await pdfService.generate(bill, paperSize: paperSize);
        final result = await fileService.shareFile(
          bytes: bytes,
          fileName: bill.fileName(extension: 'pdf'),
          mimeType: 'application/pdf',
        );
        _showShareResult(result.status);
      case _ExportAction.printPdf:
        final info = await Printing.info();
        if (!info.canPrint) {
          _showMessage('Printing is not available on this device.');
          return;
        }
        final bytes = await pdfService.generate(bill, paperSize: paperSize);
        final submitted = await BillPrintService.instance.printPdf(
          bytes: bytes,
          documentName: bill.fileName(extension: 'pdf'),
          paperFormat: paperSize.pageFormat,
        );
        _showMessage(
          submitted ? 'Print job submitted.' : 'Printing cancelled.',
        );
      case _ExportAction.saveFullJpg:
        final page = await BillJpgService().createFullBillImage(
          bill,
          paperSize: paperSize,
        );
        final saved = await fileService.saveFile(
          bytes: page.bytes,
          fileName: page.fileName,
          mimeType: 'image/jpeg',
        );
        if (mounted) {
          _showMessage(saved ? _saveSuccessMessage('JPG') : 'Save cancelled.');
        }
      case _ExportAction.shareFullJpg:
        final page = await BillJpgService().createFullBillImage(
          bill,
          paperSize: paperSize,
        );
        final result = await fileService.shareFile(
          bytes: page.bytes,
          fileName: page.fileName,
          mimeType: 'image/jpeg',
        );
        _showShareResult(result.status);
      case _ExportAction.savePageJpgs:
        final pages = await BillJpgService().createPageImages(
          bill,
          paperSize: paperSize,
        );
        final saved = await fileService.savePageImages(pages);
        if (mounted) {
          _showMessage(
            saved
                ? _saveSuccessMessage('Bill page images')
                : 'Saving page images cancelled.',
          );
        }
      case _ExportAction.sharePageJpgs:
        final pages = await BillJpgService().createPageImages(
          bill,
          paperSize: paperSize,
        );
        final result = await fileService.sharePageImages(pages);
        _showShareResult(result.status);
    }
  }

  void _showShareResult(ShareResultStatus status) {
    switch (status) {
      case ShareResultStatus.success:
        _showMessage(
          'Share sheet opened. The receiving app will confirm when it is sent.',
        );
      case ShareResultStatus.dismissed:
        _showMessage('Sharing cancelled.');
      case ShareResultStatus.unavailable:
        _showMessage('Sharing is not available on this device.');
    }
  }

  String _progressFor(_ExportAction action) => switch (action) {
    _ExportAction.savePdf ||
    _ExportAction.sharePdf ||
    _ExportAction.printPdf => 'Preparing PDF...',
    _ExportAction.saveFullJpg ||
    _ExportAction.shareFullJpg => 'Rendering full bill image...',
    _ExportAction.savePageJpgs ||
    _ExportAction.sharePageJpgs => 'Rendering bill pages...',
  };

  String _saveSuccessMessage(String fileType) => kIsWeb
      ? 'Browser download or share started for $fileType.'
      : '$fileType saved successfully.';

  String _failureMessage(_ExportAction action, Object error) {
    if (error is BillJpgExportException) return error.message;
    return switch (action) {
      _ExportAction.savePdf || _ExportAction.saveFullJpg =>
        'The file could not be saved to the selected location.',
      _ExportAction.sharePdf ||
      _ExportAction.shareFullJpg ||
      _ExportAction.sharePageJpgs =>
        'Unable to share this bill. Please try again.',
      _ExportAction.printPdf =>
        'Unable to open the print service. Please try again.',
      _ExportAction.savePageJpgs => 'Unable to save all bill page images. Some earlier pages may already be saved.',
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: _isBusy ? _progressMessage : widget.buttonLabel,
          icon: _isBusy ? null : Icons.ios_share_rounded,
          onPressed: _isBusy || _isSelectingOptions ? null : _openOptions,
          loading: _isBusy,
        ),
        if (_isBusy) ...[
          const SizedBox(height: AppSpacing.sm),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}

class _ExportOptionsSheet extends StatelessWidget {
  const _ExportOptionsSheet();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.md,
        AppSpacing.pagePadding,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Export Bill', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Save a copy, share it with another app, or print it. '
            'This does not save or change the bill in BillMate.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionTitle(context, 'PDF document'),
          _option(
            context,
            icon: Icons.save_alt_rounded,
            title: 'Save PDF to device',
            action: _ExportAction.savePdf,
          ),
          _option(
            context,
            icon: Icons.share_outlined,
            title: 'Share PDF',
            action: _ExportAction.sharePdf,
          ),
          _option(
            context,
            icon: Icons.print_outlined,
            title: 'Print bill',
            action: _ExportAction.printPdf,
          ),
          const Divider(),
          _sectionTitle(context, 'JPG images'),
          _option(
            context,
            icon: Icons.image_outlined,
            title: 'Save full-bill JPG',
            subtitle: 'One long image; very long bills may be too large.',
            action: _ExportAction.saveFullJpg,
          ),
          _option(
            context,
            icon: Icons.ios_share_rounded,
            title: 'Share full-bill JPG',
            action: _ExportAction.shareFullJpg,
          ),
          _option(
            context,
            icon: Icons.collections_outlined,
            title: 'Save page-by-page JPGs',
            subtitle: 'Choose a folder for all page images.',
            action: _ExportAction.savePageJpgs,
          ),
          _option(
            context,
            icon: Icons.photo_library_outlined,
            title: 'Share page-by-page JPGs',
            subtitle: 'Shares all pages together where supported.',
            action: _ExportAction.sharePageJpgs,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String title,
    required _ExportAction action,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}
