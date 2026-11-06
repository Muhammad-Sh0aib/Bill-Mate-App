import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_dimensions.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../bills/application/bill_history_refresh_provider.dart';
import '../../../bills/application/bill_repository_provider.dart';
import '../../../bills/data/bill_repository.dart';
import '../../../bills/domain/bill_amount.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';

/// Compact, honest empty state displayed in the Recent Bills section.
///
/// Indicates that saved workshop bills will appear here once created,
/// without fabricating sample customers, amounts, or analytics.
class RecentBillsEmptyCard extends ConsumerStatefulWidget {
  const RecentBillsEmptyCard({super.key, required this.onNewBill});

  final VoidCallback onNewBill;

  @override
  ConsumerState<RecentBillsEmptyCard> createState() =>
      _RecentBillsEmptyCardState();
}

class _RecentBillsEmptyCardState extends ConsumerState<RecentBillsEmptyCard> {
  List<BillRecord>? _bills;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ref.listenManual(billHistoryRefreshProvider, (previous, next) {
      _loadBills();
    });
    _loadBills();
  }

  Future<void> _loadBills() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final bills = await ref
          .read(billRepositoryProvider)
          .listRecentBills(limit: 3);
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _loading = false;
      });
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace,
        'Loading dashboard recent bills',
      );
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Recent Bills',
          subtitle: 'Recently generated invoices for repair jobs',
          icon: Icons.history_edu_rounded,
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_loading)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Loading recent bills...'),
                ],
              ),
            ),
          )
        else if (_error != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recent bills could not be loaded.'),
                TextButton.icon(
                  onPressed: _loadBills,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          )
        else if ((_bills ?? const []).isNotEmpty)
          ..._bills!.map(
            (bill) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _RecentBillCard(bill: bill),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.primary.withAlpha(12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_outlined,
                        size: 22,
                        color: isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.primary.withAlpha(140),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'No bills yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? const Color(0xFFE8ECF0)
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Saved bills will appear here.',
                            style: AppTextStyles.caption.copyWith(
                              color: isDark
                                  ? const Color(0xFF9BB3C6)
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Create New Bill',
                    icon: Icons.add_rounded,
                    onPressed: widget.onNewBill,
                    fullWidth: false,
                    semanticLabel: 'Create first bill from empty state',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentBillCard extends StatelessWidget {
  const _RecentBillCard({required this.bill});

  final BillRecord bill;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: () => context.pushNamed(
          RouteNames.billDetailsName,
          pathParameters: {'billId': bill.id},
        ),
        leading: Icon(
          Icons.receipt_long_outlined,
          color: dark ? const Color(0xFF90CAF9) : AppColors.primary,
        ),
        title: Text(
          bill.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(BillDateUtils.formatBillDate(bill.billDate)),
        trailing: Text(
          BillAmount.formatPaisaBigInt(bill.finalPayableInPaisa),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: dark ? const Color(0xFFE8ECF0) : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
