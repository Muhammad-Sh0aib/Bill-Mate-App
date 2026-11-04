import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_inline_message.dart';
import '../../../core/widgets/app_section_header.dart';
import '../application/bill_draft_provider.dart';
import '../domain/bill_amount.dart';
import '../domain/bill_discount.dart';
import '../domain/bill_item.dart';
import '../domain/bill_totals.dart';
import 'voice_input_button.dart';

class BillItemsSection extends ConsumerWidget {
  const BillItemsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(billDraftProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totals = const BillTotalsCalculator().calculate(
      items: draft.items,
      billDiscount: draft.billDiscount,
    );
    final hasDiscounts =
        draft.items.any((item) => item.discount.type != DiscountType.none) ||
        draft.billDiscount.type != DiscountType.none ||
        totals.totalItemDiscountInPaisa > BigInt.zero ||
        totals.billDiscountInPaisa > BigInt.zero;
    final showOriginalSubtotal =
        hasDiscounts &&
        (totals.originalSubtotalInPaisa != draft.subtotalInPaisa ||
            totals.totalItemDiscountInPaisa > BigInt.zero ||
            totals.billDiscountInPaisa > BigInt.zero);
    final showSubtotalAfterItemDiscounts =
        hasDiscounts &&
        totals.subtotalAfterItemDiscountsInPaisa !=
            totals.originalSubtotalInPaisa;
    final showBillDiscount =
        hasDiscounts &&
        (totals.billDiscountInPaisa > BigInt.zero ||
            draft.billDiscount.type != DiscountType.none);
    final showFinalPayable =
        hasDiscounts &&
        (totals.finalPayableInPaisa !=
                totals.subtotalAfterItemDiscountsInPaisa ||
            totals.billDiscountInPaisa > BigInt.zero ||
            totals.totalItemDiscountInPaisa > BigInt.zero);

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
                child: _BillItemsHeader(isDark: isDark),
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
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    indent: AppSpacing.sm,
                    endIndent: AppSpacing.sm,
                  ),
                  itemBuilder: (context, index) => _BillItemRow(
                    key: ValueKey(draft.items[index].id),
                    item: draft.items[index],
                    serialNumber: index + 1,
                  ),
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
              _BillDiscountEditor(
                billDiscount: draft.billDiscount,
                onChanged: (discount) => ref
                    .read(billDraftProvider.notifier)
                    .updateBillDiscount(discount),
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
                      const AppInlineMessage(
                        type: AppInlineMessageType.warning,
                        message: 'Subtotal is provisional until every item description and amount is complete.',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (showOriginalSubtotal)
                      _BillSummaryRow(
                        label: 'Original Subtotal',
                        value: BillAmount.formatPaisaBigInt(
                          totals.originalSubtotalInPaisa,
                        ),
                      ),
                    if (totals.totalItemDiscountInPaisa > BigInt.zero)
                      _BillSummaryRow(
                        label: 'Item Discounts',
                        value:
                            '- ${BillAmount.formatPaisaBigInt(totals.totalItemDiscountInPaisa)}',
                      ),
                    if (showSubtotalAfterItemDiscounts)
                      _BillSummaryRow(
                        label: 'Subtotal After Item Discounts',
                        value: BillAmount.formatPaisaBigInt(
                          totals.subtotalAfterItemDiscountsInPaisa,
                        ),
                      ),
                    if (showBillDiscount)
                      _BillSummaryRow(
                        label:
                            'Bill Discount${draft.billDiscount.type == DiscountType.none ? '' : ' (${draft.billDiscount.type.label})'}',
                        value:
                            '- ${BillAmount.formatPaisaBigInt(totals.billDiscountInPaisa)}',
                      ),
                    if (totals.validationSummary.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppInlineMessage(
                        type: AppInlineMessageType.warning,
                        title: 'Check discount values',
                        message: totals.validationSummary.join('\n'),
                      ),
                    ],
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    if (showFinalPayable)
                      _BillSummaryRow(
                        label: 'Final Payable',
                        value: BillAmount.formatPaisaBigInt(
                          totals.finalPayableInPaisa,
                        ),
                        isEmphasized: true,
                      ),
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

class _BillItemsHeader extends StatelessWidget {
  const _BillItemsHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFFB0C4DE) : AppColors.primary;
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Text(
            'S.No',
            style: AppTextStyles.sectionLabel.copyWith(color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Particular / Detail',
            style: AppTextStyles.sectionLabel.copyWith(color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        SizedBox(
          width: 88,
          child: Text(
            'Amount (PKR)',
            textAlign: TextAlign.end,
            style: AppTextStyles.sectionLabel.copyWith(color: color),
          ),
        ),
        const SizedBox(width: AppSpacing.touchTarget),
      ],
    );
  }
}

class _BillItemRow extends StatefulWidget {
  const _BillItemRow({
    super.key,
    required this.item,
    required this.serialNumber,
  });

  final BillItem item;
  final int serialNumber;

  @override
  State<_BillItemRow> createState() => _BillItemRowState();
}

class _BillItemRowState extends State<_BillItemRow> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _amountFocusNode;
  bool _showDescriptionError = false;
  bool _showAmountError = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.item.description,
    );
    _amountController = TextEditingController(text: widget.item.amountInput);
    _descriptionFocusNode = FocusNode()..addListener(_onDescriptionFocus);
    _amountFocusNode = FocusNode()..addListener(_onAmountFocus);
  }

  @override
  void didUpdateWidget(covariant _BillItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_descriptionController, widget.item.description);
    _syncController(_amountController, widget.item.amountInput);
  }

  @override
  void dispose() {
    _descriptionFocusNode
      ..removeListener(_onDescriptionFocus)
      ..dispose();
    _amountFocusNode
      ..removeListener(_onAmountFocus)
      ..dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onDescriptionFocus() {
    if (!_descriptionFocusNode.hasFocus && !_showDescriptionError) {
      setState(() => _showDescriptionError = true);
    }
  }

  void _onAmountFocus() {
    if (!_amountFocusNode.hasFocus && !_showAmountError) {
      setState(() => _showAmountError = true);
    }
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  String? get _descriptionError =>
      _showDescriptionError && widget.item.description.trim().isEmpty
      ? 'Enter a description.'
      : null;

  String? get _amountError {
    if (!_showAmountError) return null;
    return widget.item.amountInPaisa == null
        ? widget.item.amountInput.trim().isEmpty
              ? 'Enter an amount.'
              : 'Enter a valid non-negative amount (up to 2 decimals).'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary;

    return Consumer(
      builder: (context, ref, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 420;
            final amountField = SizedBox(
              width: compact ? 78 : 88,
              child: Semantics(
                label:
                    'Amount for item ${widget.serialNumber}, Pakistani rupees',
                textField: true,
                child: TextField(
                  key: ValueKey('bill-item-amount-${widget.item.id}'),
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.inputText.copyWith(color: foreground),
                  decoration: _inputDecoration(
                    context,
                    hint: '0.00',
                    errorText: _amountError,
                  ),
                  onChanged: (value) => ref
                      .read(billDraftProvider.notifier)
                      .updateItemAmount(widget.item.id, value),
                ),
              ),
            );

            final descriptionField = Expanded(
              child: Semantics(
                label: 'Particular or detail for item ${widget.serialNumber}',
                textField: true,
                child: TextField(
                  key: ValueKey('bill-item-description-${widget.item.id}'),
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  style: AppTextStyles.inputText.copyWith(color: foreground),
                  decoration: _inputDecoration(
                    context,
                    hint: 'Service or repair detail',
                    errorText: _descriptionError,
                    suffixIcon: VoiceInputButton(
                      fieldLabel: 'item detail',
                      onResult: (value) {
                        final cleaned = value.trim();
                        if (cleaned.isEmpty) return;
                        _descriptionController.value = TextEditingValue(
                          text: cleaned,
                          selection: TextSelection.collapsed(
                            offset: cleaned.length,
                          ),
                        );
                        ref
                            .read(billDraftProvider.notifier)
                            .updateItemDescription(widget.item.id, cleaned);
                      },
                    ),
                  ),
                  onChanged: (value) => ref
                      .read(billDraftProvider.notifier)
                      .updateItemDescription(widget.item.id, value),
                  onSubmitted: (_) => _amountFocusNode.requestFocus(),
                ),
              ),
            );

            final itemRow = compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 26,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Text(
                                '${widget.serialNumber}.',
                                key: ValueKey(
                                  'bill-item-serial-${widget.item.id}',
                                ),
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
                          descriptionField,
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Spacer(),
                          amountField,
                          const SizedBox(width: AppSpacing.xs),
                          SizedBox(
                            width: AppSpacing.touchTarget,
                            height: AppSpacing.touchTarget,
                            child: Semantics(
                              label: 'Delete item ${widget.serialNumber}',
                              button: true,
                              child: IconButton(
                                tooltip: 'Delete item ${widget.serialNumber}',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: AppSpacing.touchTarget,
                                  height: AppSpacing.touchTarget,
                                ),
                                onPressed: () => _deleteItem(ref),
                                icon: const Icon(Icons.delete_outline_rounded),
                                color: isDark
                                    ? const Color(0xFFE59898)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 26,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            '${widget.serialNumber}.',
                            key: ValueKey('bill-item-serial-${widget.item.id}'),
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
                      descriptionField,
                      const SizedBox(width: AppSpacing.xs),
                      amountField,
                      SizedBox(
                        width: AppSpacing.touchTarget,
                        height: AppSpacing.touchTarget,
                        child: Semantics(
                          label: 'Delete item ${widget.serialNumber}',
                          button: true,
                          child: IconButton(
                            tooltip: 'Delete item ${widget.serialNumber}',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: AppSpacing.touchTarget,
                              height: AppSpacing.touchTarget,
                            ),
                            onPressed: () => _deleteItem(ref),
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: isDark
                                ? const Color(0xFFE59898)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  itemRow,
                  const SizedBox(height: AppSpacing.sm),
                  _DiscountEditor(
                    itemId: widget.item.id,
                    discount: widget.item.discount,
                    onChanged: (discount) => ref
                        .read(billDraftProvider.notifier)
                        .updateItemDiscount(widget.item.id, discount),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    String? errorText,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 12,
      ),
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF40566B) : AppColors.border,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> _deleteItem(WidgetRef ref) async {
    final populated =
        widget.item.description.trim().isNotEmpty ||
        widget.item.amountInput.trim().isNotEmpty;
    if (populated) {
      final description = widget.item.description.trim();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete item ${widget.serialNumber}?'),
          content: Text(
            description.isEmpty
                ? 'This item and its amount will be removed from the bill.'
                : '"$description" will be removed from the bill.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    if (!mounted) return;
    ref.read(billDraftProvider.notifier).deleteItem(widget.item.id);
  }
}

class _BillDiscountEditor extends StatelessWidget {
  const _BillDiscountEditor({
    required this.billDiscount,
    required this.onChanged,
  });

  final BillDiscount billDiscount;
  final ValueChanged<BillDiscount> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Bill Discount', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 12,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DiscountType>(
                key: const ValueKey('bill-discount-type'),
                value: billDiscount.type,
                isExpanded: true,
                items: DiscountType.values
                    .map(
                      (type) => DropdownMenuItem<DiscountType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(
                    billDiscount.copyWith(
                      type: value,
                      fixedInput: value == DiscountType.fixed
                          ? billDiscount.fixedInput
                          : '',
                      percentageInput: value == DiscountType.percentage
                          ? billDiscount.percentageInput
                          : '',
                    ),
                  );
                },
              ),
            ),
          ),
          if (billDiscount.type == DiscountType.fixed) ...[
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('bill-discount-value'),
              initialValue: billDiscount.fixedInput,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter discount in PKR',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  onChanged(billDiscount.copyWith(fixedInput: value)),
            ),
          ] else if (billDiscount.type == DiscountType.percentage) ...[
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('bill-discount-value'),
              initialValue: billDiscount.percentageInput,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter percentage (0–100)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  onChanged(billDiscount.copyWith(percentageInput: value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscountEditor extends StatelessWidget {
  const _DiscountEditor({
    required this.itemId,
    required this.discount,
    required this.onChanged,
  });

  final String itemId;
  final BillDiscount discount;
  final ValueChanged<BillDiscount> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Item discount',
            style: AppTextStyles.sectionLabel.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 12,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DiscountType>(
                key: ValueKey('bill-item-discount-$itemId-type'),
                value: discount.type,
                isExpanded: true,
                items: DiscountType.values
                    .map(
                      (type) => DropdownMenuItem<DiscountType>(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  onChanged(
                    discount.copyWith(
                      type: value,
                      fixedInput: value == DiscountType.fixed
                          ? discount.fixedInput
                          : '',
                      percentageInput: value == DiscountType.percentage
                          ? discount.percentageInput
                          : '',
                    ),
                  );
                },
              ),
            ),
          ),
          if (discount.type == DiscountType.fixed) ...[
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              key: ValueKey('bill-item-discount-$itemId-value'),
              initialValue: discount.fixedInput,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter discount in PKR',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  onChanged(discount.copyWith(fixedInput: value)),
            ),
          ] else if (discount.type == DiscountType.percentage) ...[
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              key: ValueKey('bill-item-discount-$itemId-value'),
              initialValue: discount.percentageInput,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter percentage (0–100)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  onChanged(discount.copyWith(percentageInput: value)),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillSummaryRow extends StatelessWidget {
  const _BillSummaryRow({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = isEmphasized
        ? AppTextStyles.amountSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFFE8ECF0) : AppColors.primary,
          )
        : AppTextStyles.bodyMedium.copyWith(
            color: isDark ? const Color(0xFFE8ECF0) : AppColors.textPrimary,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, textAlign: TextAlign.end, style: style),
        ],
      ),
    );
  }
}
