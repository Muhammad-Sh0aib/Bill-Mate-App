import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../bill_export/domain/bill_document_data.dart';
import '../../bill_export/presentation/bill_export_actions.dart';
import '../../bills/application/bill_history_refresh_provider.dart';
import '../../bills/application/bill_repository_provider.dart';
import '../../bills/data/bill_repository.dart';
import '../../bills/domain/bill_amount.dart';
import '../../bills/domain/bill_totals.dart';

class BillDetailsScreen extends ConsumerStatefulWidget {
  const BillDetailsScreen({super.key, required this.billId});

  final String billId;

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  BillRecord? _bill;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bill = await ref
          .read(billRepositoryProvider)
          .loadById(widget.billId);
      if (!mounted) return;
      setState(() {
        _bill = bill;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'This bill could not be loaded from local storage.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBill() async {
    final bill = _bill;
    if (bill == null || _isDeleting) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete this bill?',
      message:
          'This removes ${bill.customerName} and its bill items from this device. This cannot be undone.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete Bill',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      final deleted = await ref
          .read(billRepositoryProvider)
          .deleteBill(bill.id);
      if (!mounted) return;
      if (!deleted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This bill was not found or was already deleted.'),
          ),
        );
        return;
      }
      ref.read(billHistoryRefreshProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill deleted from this device.')),
      );
      context.goNamed(RouteNames.historyName);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill could not be deleted. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bill = _bill;
    return Scaffold(
      appBar: AppAppBar(
        title: 'Bill Details',
        subtitle: bill?.customerName ?? 'Saved bill',
        actions: [
          if (bill != null)
            IconButton(
              tooltip: 'Delete bill',
              onPressed: _isDeleting ? null : _deleteBill,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingIndicator.centered(
                message: 'Loading bill details...',
              )
            : _error != null
            ? AppEmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load bill',
                description: _error!,
                actionLabel: 'Retry',
                onAction: _loadBill,
              )
            : bill == null
            ? AppEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Bill not found',
                description: 'It may have been deleted from this device.',
                actionLabel: 'Back to bills',
                onAction: () => context.goNamed(RouteNames.historyName),
              )
            : _buildDetails(bill),
      ),
    );
  }

  Widget _buildDetails(BillRecord bill) {
    final totals = const BillTotalsCalculator().calculate(
      items: bill.items,
      billDiscount: bill.billDiscount,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pagePadding),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bill.companyNameSnapshot,
                style: AppTextStyles.headingSmall.copyWith(
                  color: isDark ? const Color(0xFFE8ECF0) : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(bill.companyPhoneSnapshot),
              const Divider(height: AppSpacing.lg),
              _DetailRow(label: 'Customer', value: bill.customerName),
              _DetailRow(
                label: 'Bill date',
                value: BillDateUtils.formatBillDate(bill.billDate),
              ),
              if (bill.billNumber != null && bill.billNumber!.isNotEmpty)
                _DetailRow(label: 'Bill number', value: bill.billNumber!),
              _DetailRow(
                label: 'Saved',
                value: BillDateUtils.formatDateTime(bill.createdAt.toLocal()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bill Items', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              if (bill.items.isEmpty)
                const Text('No item details were stored.')
              else
                ...List.generate(bill.items.length, (index) {
                  final item = bill.items[index];
                  final itemTotals = index < totals.itemTotals.length
                      ? totals.itemTotals[index]
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${index + 1}. '),
                            Expanded(child: Text(item.description)),
                            Text(
                              BillAmount.formatPaisaBigInt(
                                itemTotals?.originalAmountInPaisa ??
                                    BigInt.zero,
                              ),
                            ),
                          ],
                        ),
                        if ((itemTotals?.discountAmountInPaisa ?? BigInt.zero) >
                            BigInt.zero)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSpacing.lg,
                              top: 2,
                            ),
                            child: Text(
                              'Item discount: -${BillAmount.formatPaisaBigInt(itemTotals!.discountAmountInPaisa)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                label: 'Original subtotal',
                value: BillAmount.formatPaisaBigInt(
                  bill.originalSubtotalInPaisa,
                ),
              ),
              if (bill.totalItemDiscountInPaisa > BigInt.zero)
                _DetailRow(
                  label: 'Item discounts',
                  value:
                      '-${BillAmount.formatPaisaBigInt(bill.totalItemDiscountInPaisa)}',
                  valueColor: AppColors.success,
                ),
              _DetailRow(
                label: 'Subtotal after item discounts',
                value: BillAmount.formatPaisaBigInt(
                  bill.subtotalAfterItemDiscountsInPaisa,
                ),
              ),
              if (bill.billDiscountAmountInPaisa > BigInt.zero)
                _DetailRow(
                  label: 'Bill discount',
                  value:
                      '-${BillAmount.formatPaisaBigInt(bill.billDiscountAmountInPaisa)}',
                  valueColor: AppColors.success,
                ),
              const Divider(height: AppSpacing.lg),
              _DetailRow(
                label: 'Final payable',
                value: BillAmount.formatPaisaBigInt(bill.finalPayableInPaisa),
                emphasized: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Preview Bill',
          icon: Icons.preview_outlined,
          onPressed: () => context.pushNamed(
            RouteNames.billPreviewName,
            queryParameters: {'billId': bill.id},
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BillExportActions(
          bill: BillDocumentData.fromRecord(bill),
          paperSize: BillPaperSize.a4,
          buttonLabel: 'Export / Print / Share',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Edit Saved Bill',
          icon: Icons.edit_outlined,
          onPressed: () => context.goNamed(
            RouteNames.editSavedBillName,
            pathParameters: {'billId': bill.id},
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Delete Bill',
          icon: Icons.delete_outline_rounded,
          variant: AppButtonVariant.destructive,
          onPressed: _isDeleting ? null : _deleteBill,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style =
        (emphasized ? AppTextStyles.headingSmall : AppTextStyles.bodyMedium)
            .copyWith(
              color: valueColor,
              fontWeight: emphasized ? FontWeight.w700 : null,
            );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(value, textAlign: TextAlign.end, style: style),
          ),
        ],
      ),
    );
  }
}
