import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../features/bills/application/bill_history_refresh_provider.dart';
import '../../../features/bills/application/bill_repository_provider.dart';
import '../../../features/bills/data/bill_repository.dart';
import '../../../features/bills/domain/bill_amount.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<BillRecord> _bills = const [];
  Set<String> _latestBillIds = const {};
  int _totalCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(billRepositoryProvider);
      final query = _searchController.text.trim();
      final bills = query.isEmpty
          ? await repository.listRecentBills()
          : await repository.searchBills(query);
      final latest = await repository.listRecentBills();
      final totalCount = await repository.countCompletedBills();
      if (!mounted) return;
      setState(() {
        _bills = bills;
        _latestBillIds = latest.map((bill) => bill.id).toSet();
        _totalCount = totalCount;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Bills could not be loaded. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), _loadHistory);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(billHistoryRefreshProvider, (previous, next) {
      if (previous != next) _loadHistory();
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Previous Bills',
        subtitle: 'Workshop Bill History',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.md,
                AppSpacing.pagePadding,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search customer, bill number, or ID',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: isSearching
                      ? IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            _loadHistory();
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    isSearching
                        ? Icons.manage_search_rounded
                        : Icons.history_rounded,
                    size: AppIconSize.sm + 4,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isSearching ? 'Search results' : 'Latest seven bills',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$_totalCount saved',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? const Color(0xFF9BB3C6)
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(isSearching, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isSearching, bool isDark) {
    if (_isLoading) {
      return const AppLoadingIndicator.centered(
        message: 'Loading saved bills...',
      );
    }
    if (_error != null) {
      return AppEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load bills',
        description: _error!,
        actionLabel: 'Retry',
        onAction: _loadHistory,
      );
    }
    if (_bills.isEmpty) {
      return AppEmptyState(
        icon: isSearching
            ? Icons.search_off_rounded
            : Icons.receipt_long_outlined,
        title: isSearching ? 'No matching bills' : 'No bills saved yet',
        description: isSearching
            ? 'Try another customer name, bill number, or ID.'
            : 'Bills you save will appear here. Older bills remain available through search.',
        actionLabel: isSearching ? null : 'Create New Bill',
        onAction: isSearching
            ? null
            : () => context.goNamed(RouteNames.newBillName),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        itemCount: _bills.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return _BillHistoryCard(
            bill: bill,
            isOlderSearchResult:
                isSearching && !_latestBillIds.contains(bill.id),
            onTap: () => context.goNamed(
              RouteNames.billDetailsName,
              pathParameters: {'billId': bill.id},
            ),
          );
        },
      ),
    );
  }
}

class _BillHistoryCard extends StatelessWidget {
  const _BillHistoryCard({
    required this.bill,
    required this.isOlderSearchResult,
    required this.onTap,
  });

  final BillRecord bill;
  final bool isOlderSearchResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceElevatedDark
                  : AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: isDark ? const Color(0xFF90CAF9) : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${BillDateUtils.formatShortDate(bill.billDate)}'
                  '${bill.billNumber == null ? '' : ' • ${bill.billNumber}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? const Color(0xFF9BB3C6)
                        : AppColors.textSecondary,
                  ),
                ),
                if (isOlderSearchResult) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Older bill',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? const Color(0xFFFFCC80)
                          : AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                BillAmount.formatPaisaBigInt(bill.finalPayableInPaisa),
                style: AppTextStyles.amountSmall.copyWith(
                  color: isDark ? const Color(0xFFE8ECF0) : AppColors.primary,
                ),
              ),
              const SizedBox(height: 3),
              Icon(
                Icons.chevron_right_rounded,
                size: AppIconSize.md,
                color: isDark
                    ? const Color(0xFF9BB3C6)
                    : AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
