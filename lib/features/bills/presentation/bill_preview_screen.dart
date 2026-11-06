import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../bill_export/domain/bill_document_data.dart';
import '../../bill_export/presentation/bill_export_actions.dart';
import '../application/bill_draft_provider.dart';
import '../application/bill_repository_provider.dart';
import '../data/bill_repository.dart';
import '../domain/bill_amount.dart';
import '../domain/bill_discount.dart';
import '../domain/bill_draft.dart';
import '../domain/bill_item.dart';
import '../domain/bill_totals.dart';

enum BillPreviewPaperSize {
  a4('A4', Size(794, 1123)),
  a5('A5', Size(559, 794)),
  compact('Compact', Size(420, 680));

  const BillPreviewPaperSize(this.label, this.size);

  final String label;
  final Size size;

  BillPaperSize get exportSize => switch (this) {
    BillPreviewPaperSize.a4 => BillPaperSize.a4,
    BillPreviewPaperSize.a5 => BillPaperSize.a5,
    BillPreviewPaperSize.compact => BillPaperSize.compact,
  };
}

class BillPreviewScreen extends ConsumerStatefulWidget {
  const BillPreviewScreen({
    super.key,
    this.billId,
    this.billRecord,
    this.billDraft,
  });

  final String? billId;
  final BillRecord? billRecord;
  final BillDraft? billDraft;

  @override
  ConsumerState<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends ConsumerState<BillPreviewScreen> {
  BillPreviewPaperSize _paperSize = BillPreviewPaperSize.compact;
  BillRecord? _loadedBill;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.billId != null && widget.billRecord == null) {
      _loadBill();
    }
  }

  Future<void> _loadBill() async {
    final billId = widget.billId;
    if (billId == null) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final bill = await ref.read(billRepositoryProvider).loadById(billId);
      if (!mounted) return;
      setState(() {
        _loadedBill = bill;
        _isLoading = false;
        if (bill == null) {
          _loadError = 'This bill could not be found in local storage.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'This bill could not be loaded from storage.';
        _isLoading = false;
      });
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        widget.billId == null ? RouteNames.newBill : RouteNames.history,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final BillDraft draft = widget.billDraft ?? ref.watch(billDraftProvider);
    final BillRecord? savedBill = widget.billRecord ?? _loadedBill;

    if ((widget.billId != null || widget.billRecord != null) && _isLoading) {
      return Scaffold(
        appBar: AppAppBar(
          title: 'Bill Preview',
          subtitle: 'Loading invoice...',
          showBackButton: true,
          onBack: _handleBack,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppAppBar(
          title: 'Bill Preview',
          subtitle: 'Unable to load',
          showBackButton: true,
          onBack: _handleBack,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadError!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                if (widget.billId != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _loadBill,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final items = savedBill?.items ?? draft.items;
    final billDiscount = savedBill?.billDiscount ?? draft.billDiscount;
    final totals = const BillTotalsCalculator().calculate(
      items: items,
      billDiscount: billDiscount,
      previousRemainingPaisa:
          savedBill?.previousRemainingInPaisa.toInt() ??
          (BillAmount.parsePaisa(draft.previousRemainingInput) ?? 0),
      advancePaymentPaisa:
          savedBill?.advancePaymentInPaisa.toInt() ??
          (BillAmount.parsePaisa(draft.advancePaymentInput) ?? 0),
    );

    final companyName =
        (savedBill?.companyNameSnapshot ?? draft.companySnapshot.name).trim();
    final companyPhone =
        (savedBill?.companyPhoneSnapshot ?? draft.companySnapshot.phone).trim();
    final companyAddress = savedBill?.companyAddressSnapshot?.trim();
    final customerName = (savedBill?.customerName ?? draft.customerName).trim();
    final billDate = savedBill?.billDate ?? draft.billDate;
    final billNumber = savedBill?.billNumber;
    final effectiveCompanyName = companyName.isNotEmpty || savedBill != null
        ? companyName
        : AppConfig.defaultCompanyName;
    final effectiveCompanyPhone = companyPhone.isNotEmpty || savedBill != null
        ? companyPhone
        : AppConfig.defaultCompanyPhone;
    final effectiveAddress = companyAddress?.isNotEmpty == true
        ? companyAddress
        : null;
    final document = savedBill == null
        ? BillDocumentData.fromDraft(draft)
        : BillDocumentData.fromRecord(savedBill);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Bill Preview',
        subtitle: 'Printable invoice',
        showBackButton: true,
        onBack: _handleBack,
        actions: [
          _PaperSizeSelector(
            value: _paperSize,
            onChanged: (value) {
              if (value != null) {
                setState(() => _paperSize = value);
              }
            },
          ),
        ],
      ),
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: SingleChildScrollView(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: _PaperDocument(
                  paperSize: _paperSize,
                  companyName: effectiveCompanyName,
                  companyPhone: effectiveCompanyPhone,
                  companyAddress: effectiveAddress,
                  customerName: customerName.isNotEmpty
                      ? customerName
                      : 'Customer',
                  billDate: billDate,
                  billNumber: billNumber,
                  items: items,
                  totals: totals,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: BillExportActions(
            bill: document,
            paperSize: _paperSize.exportSize,
            buttonLabel: 'Export / Save / Share',
          ),
        ),
      ),
    );
  }
}

class _PaperSizeSelector extends StatelessWidget {
  const _PaperSizeSelector({required this.value, required this.onChanged});

  final BillPreviewPaperSize value;
  final ValueChanged<BillPreviewPaperSize?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: DropdownButton<BillPreviewPaperSize>(
          value: value,
          isDense: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          iconEnabledColor: Theme.of(context).colorScheme.onSurface,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: BillPreviewPaperSize.values
              .map(
                (size) =>
                    DropdownMenuItem(value: size, child: Text(size.label)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PaperDocument extends StatelessWidget {
  const _PaperDocument({
    required this.paperSize,
    required this.companyName,
    required this.companyPhone,
    required this.companyAddress,
    required this.customerName,
    required this.billDate,
    required this.billNumber,
    required this.items,
    required this.totals,
  });

  final BillPreviewPaperSize paperSize;
  final String companyName;
  final String companyPhone;
  final String? companyAddress;
  final String customerName;
  final DateTime billDate;
  final String? billNumber;
  final List<BillItem> items;
  final BillTotals totals;

  @override
  Widget build(BuildContext context) {
    final width = paperSize.size.width;
    final tableWidth = width - 56;
    final hasDiscounts =
        totals.totalItemDiscountInPaisa > BigInt.zero ||
        totals.billDiscountInPaisa > BigInt.zero;
    final hasPaymentAdjustments =
        totals.previousRemainingInPaisa > BigInt.zero ||
        totals.advancePaymentInPaisa > BigInt.zero;
    final discountRows = <_SummaryRowData>[];

    if (hasDiscounts) {
      discountRows.add(
        _SummaryRowData(
          label: 'Original Subtotal',
          value: BillAmount.formatPaisaBigInt(totals.originalSubtotalInPaisa),
        ),
      );
    }

    if (totals.totalItemDiscountInPaisa > BigInt.zero) {
      discountRows.add(
        _SummaryRowData(
          label: 'Item Discounts',
          value:
              '-${BillAmount.formatPaisaBigInt(totals.totalItemDiscountInPaisa)}',
          negative: true,
        ),
      );
    }

    if (totals.totalItemDiscountInPaisa > BigInt.zero) {
      discountRows.add(
        _SummaryRowData(
          label: 'Subtotal After Item Discounts',
          value: BillAmount.formatPaisaBigInt(
            totals.subtotalAfterItemDiscountsInPaisa,
          ),
        ),
      );
    }

    if (totals.billDiscountInPaisa > BigInt.zero) {
      final label = totals.billDiscount.type == DiscountType.percentage
          ? 'Overall Discount (${_formatPercentageLabel(totals.billDiscount)})'
          : 'Overall Discount (${totals.billDiscount.fixedInput} PKR fixed)';
      discountRows.add(
        _SummaryRowData(
          label: label,
          value: '-${BillAmount.formatPaisaBigInt(totals.billDiscountInPaisa)}',
          negative: true,
        ),
      );
    }

    final finalPayable = BillAmount.formatPaisaBigInt(
      totals.finalPayableInPaisa,
    );
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      decoration: BoxDecoration(
        color: AppColors.documentSurface,
        border: Border.all(color: AppColors.documentBorder, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: AppColors.documentTextPrimary,
          fontFamily: 'Roboto',
          fontSize: 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (companyPhone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            companyPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (companyAddress != null &&
                          companyAddress!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            companyAddress!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'BILL / INVOICE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      BillDateUtils.formatBillDate(billDate),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (billNumber != null && billNumber!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Bill No: $billNumber',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoBlock(
                    title: 'Customer / Company Name',
                    value: customerName,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 160,
                  child: _InfoBlock(
                    title: 'Bill Date',
                    value: BillDateUtils.formatBillDate(billDate),
                    alignRight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: tableWidth,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(44),
                  1: FlexColumnWidth(),
                  2: FixedColumnWidth(120),
                },
                border: const TableBorder(
                  verticalInside: BorderSide(color: AppColors.border),
                  horizontalInside: BorderSide(color: AppColors.border),
                  top: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                ),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                    ),
                    children: [
                      _TableHeaderCell('S.No'),
                      _TableHeaderCell('Particular / Detail'),
                      _TableHeaderCell('Amount', alignRight: true),
                    ],
                  ),
                  ...List.generate(items.length, (index) {
                    final item = items[index];
                    final itemTotals = index < totals.itemTotals.length
                        ? totals.itemTotals[index]
                        : null;
                    final discountAmount =
                        itemTotals?.discountAmountInPaisa ?? BigInt.zero;
                    final hasDiscount = discountAmount > BigInt.zero;
                    final itemValue =
                        itemTotals?.originalAmountInPaisa ??
                        BigInt.from(item.amountInPaisa ?? 0);
                    final itemLabel = item.description.trim().isEmpty
                        ? 'Item ${index + 1}'
                        : item.description;

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'Item Discount (${_itemDiscountLabel(item.discount)}): -${BillAmount.formatPaisaBigInt(discountAmount)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    'Net Item Amount: ${BillAmount.formatPaisaBigInt(itemTotals!.netAmountInPaisa)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            BillAmount.formatPaisaBigInt(itemValue),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 260,
                child: Column(
                  children: [
                    for (final row in discountRows)
                      _SummaryRow(
                        label: row.label,
                        value: row.value,
                        negative: row.negative,
                      ),
                    const Divider(height: 18, color: AppColors.divider),
                    if (hasPaymentAdjustments)
                      _SummaryRow(
                        label: 'Bill Payable',
                        value: finalPayable,
                        emphasized: true,
                      ),
                    if (hasPaymentAdjustments &&
                        totals.previousRemainingInPaisa > BigInt.zero)
                      _SummaryRow(
                        label: 'Previous Remaining',
                        value: BillAmount.formatPaisaBigInt(
                          totals.previousRemainingInPaisa,
                        ),
                      ),
                    if (hasPaymentAdjustments &&
                        totals.advancePaymentInPaisa > BigInt.zero)
                      _SummaryRow(
                        label: 'Advance Payment',
                        value:
                            '-${BillAmount.formatPaisaBigInt(totals.advancePaymentInPaisa)}',
                        negative: true,
                      ),
                    if (!hasPaymentAdjustments ||
                        !totals.netAmountDueInPaisa.isNegative)
                      _SummaryRow(
                        label: hasPaymentAdjustments
                            ? 'NET AMOUNT DUE'
                            : 'FINAL PAYABLE',
                        value: hasPaymentAdjustments
                            ? BillAmount.formatPaisaBigInt(
                                totals.netAmountDueInPaisa,
                              )
                            : finalPayable,
                        negative: false,
                        emphasized: true,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Thank you for your business!',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Authorized Signature',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Received By / Signature',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: '${DeveloperBranding.developedBy} | '),
                    TextSpan(
                      text: DeveloperBranding.contact,
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPercentageLabel(BillDiscount discount) {
    if (discount.type != DiscountType.percentage) {
      return '0%';
    }
    final raw = discount.percentageInput.trim();
    if (raw.isEmpty) return '0%';
    return '$raw%';
  }

  static String _itemDiscountLabel(BillDiscount discount) {
    return switch (discount.type) {
      DiscountType.fixed => '${discount.fixedInput.trim()} PKR fixed',
      DiscountType.percentage =>
        '${discount.percentageInput.trim()}% percentage',
      DiscountType.none => '',
    };
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
    this.alignRight = false,
  });

  final String title;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label, {this.alignRight = false});

  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.negative = false,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool negative;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = emphasized
        ? const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )
        : const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: effectiveStyle)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: effectiveStyle.copyWith(
                color: negative ? AppColors.success : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData({
    required this.label,
    required this.value,
    this.negative = false,
  });

  final String label;
  final String value;
  final bool negative;
}
