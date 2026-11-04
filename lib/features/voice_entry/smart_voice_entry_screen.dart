import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/app_app_bar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_inline_message.dart';
import '../../core/widgets/app_text_field.dart';
import '../bills/application/bill_draft_provider.dart';
import '../bills/domain/bill_discount.dart';
import '../bills/domain/bill_item.dart';
import '../bills/presentation/voice_input_button.dart';
import 'voice_entry_models.dart';
import 'voice_entry_parser.dart';

class SmartVoiceEntryScreen extends ConsumerStatefulWidget {
  const SmartVoiceEntryScreen({super.key});

  @override
  ConsumerState<SmartVoiceEntryScreen> createState() =>
      _SmartVoiceEntryScreenState();
}

class _SmartVoiceEntryScreenState extends ConsumerState<SmartVoiceEntryScreen> {
  final TextEditingController _transcriptController = TextEditingController();
  VoiceEntryProposal? _proposal;
  bool _isParsing = false;
  bool _replaceExistingItems = false;

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  Future<void> _parseTranscript() async {
    final transcript = _transcriptController.text.trim();
    if (transcript.isEmpty) {
      setState(() {
        _proposal = const VoiceEntryProposal(
          transcript: '',
          customerName: '',
          items: <VoiceEntryItemProposal>[],
          billDiscount: BillDiscount(),
          warnings: <String>['Please speak or type a bill instruction first.'],
          issues: <String>['Empty transcript'],
        );
      });
      return;
    }

    setState(() => _isParsing = true);
    final result = const VoiceEntryParser().parse(transcript);
    if (!mounted) return;
    setState(() {
      _proposal = result;
      _isParsing = false;
    });
  }

  void _applyProposalToDraft() {
    if (_proposal == null) return;
    final draft = ref.read(billDraftProvider);
    final newItems = _proposal!.items.map((item) => item.toBillItem()).toList();
    final nextCustomer = _proposal!.customerName.trim().isNotEmpty
        ? _proposal!.customerName.trim()
        : draft.customerName;
    final existingItems = _replaceExistingItems || draft.items.isEmpty
        ? newItems
        : [...draft.items, ...newItems];

    final nextDiscount = _proposal!.billDiscount.type == DiscountType.none
        ? draft.billDiscount
        : _proposal!.billDiscount;

    final controller = ref.read(billDraftProvider.notifier);
    controller.state = draft.copyWith(
      customerName: nextCustomer,
      items: existingItems,
      billDiscount: nextDiscount,
      hasUnsavedChanges: true,
    );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);
    final hasExistingItems = draft.items.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppAppBar(
        title: 'Smart Voice Entry',
        subtitle: 'Review the proposal before it updates your bill.',
        showBackButton: true,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recognized transcript',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: isDark
                          ? const Color(0xFFE8ECF0)
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: 'Voice transcript',
                    hint: 'Speak or paste a billing instruction',
                    controller: _transcriptController,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    suffixIcon: VoiceInputButton(
                      fieldLabel: 'billing instruction',
                      tooltip: 'Use microphone for smart voice entry',
                      onResult: (value) {
                        _transcriptController.text = value;
                        _transcriptController.selection =
                            TextSelection.fromPosition(
                              TextPosition(offset: value.length),
                            );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Parse Transcript',
                          icon: Icons.auto_fix_high_rounded,
                          onPressed: _isParsing ? null : _parseTranscript,
                          loading: _isParsing,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_proposal != null) ...[
              const SizedBox(height: AppSpacing.sectionGap),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review proposal',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: isDark
                            ? const Color(0xFFE8ECF0)
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_proposal!.customerName.isNotEmpty) ...[
                      Text(
                        'Customer',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _proposal!.customerName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFE8ECF0)
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (_proposal!.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Proposed items',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._proposal!.items.asMap().entries.map((entry) {
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF40566B)
                                  : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key + 1}. ${item.description}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFE8ECF0)
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                item.amountInput.isEmpty
                                    ? 'Amount required'
                                    : item.amountInput,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                              if (item.discount.type != DiscountType.none) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Discount: ${item.discount.type.label} ${item.discount.type == DiscountType.percentage ? '${item.discount.percentageInput}%' : item.discount.fixedInput}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? const Color(0xFF9BB3C6)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                    if (_proposal!.billDiscount.type != DiscountType.none) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Whole-bill discount',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? const Color(0xFF9BB3C6)
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${_proposal!.billDiscount.type.label} ${_proposal!.billDiscount.type == DiscountType.percentage ? '${_proposal!.billDiscount.percentageInput}%' : _proposal!.billDiscount.fixedInput}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_proposal!.warnings.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppInlineMessage(
                        type: AppInlineMessageType.warning,
                        title: 'Review needed',
                        message: _proposal!.warnings.join(' '),
                      ),
                    ],
                    if (_proposal!.issues.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppInlineMessage(
                        type: AppInlineMessageType.info,
                        title: 'Parsing notes',
                        message: _proposal!.issues.join(' '),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    if (hasExistingItems) ...[
                      CheckboxListTile(
                        value: _replaceExistingItems,
                        onChanged: (value) => setState(
                          () => _replaceExistingItems = value ?? false,
                        ),
                        title: const Text('Replace existing items'),
                        subtitle: const Text(
                          'Remove current bill items before applying the proposal.',
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: hasExistingItems && !_replaceExistingItems
                                ? 'Add to Bill'
                                : 'Apply Proposal',
                            icon: Icons.check_rounded,
                            onPressed: _proposal == null || _proposal!.isEmpty
                                ? null
                                : _applyProposalToDraft,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
