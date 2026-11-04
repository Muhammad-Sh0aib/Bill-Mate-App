import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_field_group.dart';
import '../../../core/widgets/app_inline_message.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../company_settings/domain/company_details.dart';
import '../../company_settings/application/company_settings_providers.dart';
import '../application/bill_history_refresh_provider.dart';
import '../application/bill_draft_provider.dart';
import '../application/bill_repository_provider.dart';
import '../domain/bill_totals.dart';
import 'bill_draft_navigation_guard.dart';
import 'voice_input_button.dart';
import '../domain/bill_amount.dart';
import '../domain/bill_discount.dart';
import '../domain/bill_item.dart';

class NewBillScreen extends ConsumerStatefulWidget {
  const NewBillScreen({super.key, this.billId});

  final String? billId;

  @override
  ConsumerState<NewBillScreen> createState() => _NewBillScreenState();
}

class _NewBillScreenState extends ConsumerState<NewBillScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _customerFocusNode = FocusNode();
  bool _customerValidationAttempted = false;
  bool _isLoadingSavedBill = false;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(billDraftProvider.notifier).refreshDateIfUntouched();
    _customerController.text = ref.read(billDraftProvider).customerName;
    if (widget.billId != null) {
      _isLoadingSavedBill = true;
      _loadSavedBill();
    }
  }

  Future<void> _loadSavedBill() async {
    try {
      final bill = await ref
          .read(billRepositoryProvider)
          .loadById(widget.billId!);
      if (!mounted) return;
      if (bill == null) {
        setState(() {
          _loadError = 'This saved bill could not be found.';
          _isLoadingSavedBill = false;
        });
        return;
      }
      ref.read(billDraftProvider.notifier).loadSavedBill(bill);
      setState(() {
        _isLoadingSavedBill = false;
        _customerController.text = bill.customerName;
      });
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'Saving bill');
      if (!mounted) return;
      setState(() {
        _loadError = 'Saved bill data could not be loaded. Please retry.';
        _isLoadingSavedBill = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(billDraftProvider.notifier).refreshDateIfUntouched();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _customerController.dispose();
    _customerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _leaveToHome() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final mayLeave = await confirmBillDraftExit(context, ref);
    if (mounted && mayLeave) context.go(RouteNames.home);
  }

  Future<void> _selectBillDate(DateTime currentDate) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final today = ref.read(billTodayProvider)();
    final lastDate = DateTime(today.year, today.month, today.day);
    final initialDate = currentDate.isAfter(lastDate) ? lastDate : currentDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1),
      lastDate: lastDate,
      helpText: 'Select bill date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (picked != null) {
      ref.read(billDraftProvider.notifier).updateBillDate(picked);
    }
  }

  String? _validateCustomerName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a customer or company name.';
    }
    return null;
  }

  void _submitCustomerName(String value) {
    final normalizedName = value.trim();
    _customerController.value = TextEditingValue(
      text: normalizedName,
      selection: TextSelection.collapsed(offset: normalizedName.length),
    );
    ref.read(billDraftProvider.notifier).updateCustomerName(normalizedName);
    _customerValidationAttempted = true;
    _formKey.currentState?.validate();
    _customerFocusNode.unfocus();
  }

  Future<void> _saveBill() async {
    _customerValidationAttempted = true;
    if (_formKey.currentState?.validate() != true) return;
    final draft = ref.read(billDraftProvider);
    if (draft.items.isEmpty) {
      setState(() => _saveError = 'Add at least one bill item before saving.');
      return;
    }
    final totals = const BillTotalsCalculator().calculate(
      items: draft.items,
      billDiscount: draft.billDiscount,
    );
    if (!totals.isValid) {
      setState(
        () => _saveError = totals.validationSummary.isEmpty
            ? 'Complete all bill items before saving.'
            : totals.validationSummary.first,
      );
      return;
    }
    setState(() {
      _saveError = null;
      _isSaving = true;
    });
    try {
      await ref
          .read(billRepositoryProvider)
          .saveCompletedBill(
            billId: draft.id,
            customerName: draft.customerName,
            billDate: draft.billDate,
            companyNameSnapshot: draft.companySnapshot.name,
            companyPhoneSnapshot: draft.companySnapshot.phone,
            companyAddressSnapshot: null,
            items: draft.items,
            billDiscount: draft.billDiscount,
            totals: totals,
          );
      if (!mounted) return;
      ref.read(billHistoryRefreshProvider.notifier).refresh();
      ref
          .read(billDraftProvider.notifier)
          .reset(
            company: CompanyDetails(
              name: draft.companySnapshot.name,
              phone: draft.companySnapshot.phone,
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.billId == null
                ? 'Bill saved on this device.'
                : 'Saved bill updated.',
          ),
        ),
      );
      context.goNamed(RouteNames.historyName);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError =
            'Bill could not be saved. Your current entries are still here.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(billDraftProvider, (previous, next) {
      if (_customerController.text == next.customerName) return;
      _customerController.value = TextEditingValue(
        text: next.customerName,
        selection: TextSelection.collapsed(offset: next.customerName.length),
      );
    });

    final draftFields = ref.watch(
      billDraftProvider.select(
        (draft) =>
            (billDate: draft.billDate, companySnapshot: draft.companySnapshot),
      ),
    );
    final companySettings = ref.watch(companySettingsProvider);
    final companyName = draftFields.companySnapshot.name.isNotEmpty
        ? draftFields.companySnapshot.name
        : companySettings.asData?.value.name ?? AppConfig.defaultCompanyName;
    final companyPhone = draftFields.companySnapshot.phone.isNotEmpty
        ? draftFields.companySnapshot.phone
        : companySettings.asData?.value.phone ?? AppConfig.defaultCompanyPhone;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.billId == null ? 'New Bill' : 'Edit Saved Bill',
        subtitle: widget.billId == null
            ? 'Workshop Invoice Draft'
            : 'Update Existing Invoice',
        showBackButton: true,
        onBack: _leaveToHome,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: isDark
                                  ? AppColors.accentLight
                                  : AppColors.primary,
                              size: AppIconSize.lg,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Workshop Bill',
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: isDark
                                          ? const Color(0xFFE8ECF0)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    companyName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFE8ECF0)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    companyPhone,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? const Color(0xFF9BB3C6)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => context.go(
                                '${RouteNames.settings}?returnToBill=true',
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                      if (companySettings.hasError) ...[
                        const SizedBox(height: AppSpacing.sm),
                        const AppInlineMessage(
                          type: AppInlineMessageType.error,
                          title: 'Workshop details unavailable',
                          message: 'Showing default company details because saved settings could not be loaded.',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sectionGap),
                      AppFieldGroup(
                        title: 'Customer Details',
                        icon: Icons.person_outline_rounded,
                        children: [
                          AppTextField(
                            label: 'Customer / Company Name',
                            hint: 'Enter customer or company name',
                            controller: _customerController,
                            focusNode: _customerFocusNode,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.done,
                            textCapitalization: TextCapitalization.words,
                            isRequired: true,
                            validator: _validateCustomerName,
                            onChanged: (value) {
                              ref
                                  .read(billDraftProvider.notifier)
                                  .updateCustomerName(value);
                              if (_customerValidationAttempted) {
                                _formKey.currentState?.validate();
                              }
                            },
                            onSubmitted: _submitCustomerName,
                            suffixIcon: VoiceInputButton(
                              fieldLabel: 'customer name',
                              onResult: (value) {
                                final cleaned = value.trim();
                                if (cleaned.isEmpty) return;
                                _submitCustomerName(cleaned);
                              },
                            ),
                          ),
                          AppTextField(
                            key: ValueKey(draftFields.billDate),
                            label: 'Bill Date',
                            initialValue: BillDateUtils.formatShortDate(
                              draftFields.billDate,
                            ),
                            readOnly: true,
                            textInputAction: TextInputAction.none,
                            prefixIcon: const Icon(Icons.calendar_month_outlined),
                            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                            semanticLabel: 'Bill date, select a date',
                            onTap: () => _selectBillDate(draftFields.billDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AppButton(
                        label: 'Smart Voice Entry',
                        icon: Icons.mic_rounded,
                        variant: AppButtonVariant.outlined,
                        onPressed: () => context.pushNamed(
                          RouteNames.smartVoiceEntryName,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      const _NewBillItemsSection(),
                      if (_saveError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        AppInlineMessage(
                          type: AppInlineMessageType.error,
                          title: 'Unable to save bill',
                          message: _saveError!,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: 'Preview Draft',
                        icon: Icons.preview_outlined,
                        onPressed: () => context.pushNamed(RouteNames.billPreviewName),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: widget.billId == null ? 'Save Bill' : 'Update Bill',
                        icon: Icons.save_outlined,
                        loading: _isSaving,
                        onPressed: _isSaving ? null : _saveBill,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: 'Return to Home',
                        icon: Icons.home_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: _leaveToHome,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NewBillItemsSection extends ConsumerWidget {
  const _NewBillItemsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(billDraftProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          icon: Icons.build_outlined,
          title: 'Bill Items',
          subtitle: 'Service and repair details',
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: Text(
                        'S.No',
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: isDark
                              ? const Color(0xFFB0C4DE)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Particular / Detail',
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: isDark
                              ? const Color(0xFFB0C4DE)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    SizedBox(
                      width: 88,
                      child: Text(
                        'Amount (PKR)',
                        textAlign: TextAlign.end,
                        style: AppTextStyles.sectionLabel.copyWith(
                          color: isDark
                              ? const Color(0xFFB0C4DE)
                              : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.touchTarget),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (draft.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_add_outlined,
                        color: isDark
                            ? const Color(0xFF9BB3C6)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'No items yet. Add a service or repair entry.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? const Color(0xFF9BB3C6)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: draft.items.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: AppSpacing.sm,
                    endIndent: AppSpacing.sm,
                  ),
                  itemBuilder: (context, index) {
                    final item = draft.items[index];
                    final serialNumber = index + 1;
                    final descriptionController = TextEditingController(
                      text: item.description,
                    );
                    final amountController = TextEditingController(
                      text: item.amountInput,
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                '$serialNumber.',
                                key: ValueKey('bill-item-serial-${item.id}'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark
                                      ? const Color(0xFFB0C4DE)
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextField(
                              key: ValueKey('bill-item-description-${item.id}'),
                              controller: descriptionController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => ref
                                  .read(billDraftProvider.notifier)
                                  .updateItemDescription(item.id, value),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              key: ValueKey('bill-item-amount-${item.id}'),
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => ref
                                  .read(billDraftProvider.notifier)
                                  .updateItemAmount(item.id, value),
                            ),
                          ),
                          SizedBox(
                            width: AppSpacing.touchTarget,
                            height: AppSpacing.touchTarget,
                            child: Semantics(
                              label: 'Delete item $serialNumber',
                              button: true,
                              child: IconButton(
                                tooltip: 'Delete item $serialNumber',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: AppSpacing.touchTarget,
                                  height: AppSpacing.touchTarget,
                                ),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete item $serialNumber?'),
                                      content: const Text(
                                        'This item will be removed from the bill.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    ref
                                        .read(billDraftProvider.notifier)
                                        .deleteItem(item.id);
                                  }
                                },
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: isDark
                                    ? const Color(0xFFE59898)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(billDraftProvider.notifier).addItem(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Item'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      minimumSize: const Size(48, AppSpacing.touchTarget),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Subtotal',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: isDark
                                  ? const Color(0xFFE8ECF0)
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          BillAmount.formatPaisaBigInt(draft.subtotalInPaisa),
                          key: const ValueKey('bill-subtotal'),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.amountSmall.copyWith(
                            color: isDark
                                ? const Color(0xFFE8ECF0)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (draft.items.isEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'No charges entered',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ] else if (draft.hasIncompleteItems) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Subtotal is provisional until every item description and amount is complete.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
