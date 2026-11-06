import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_dimensions.dart';
import '../../../core/utils/decimal_input_formatter.dart';
import '../../../core/widgets/app_field_group.dart';
import '../../../core/widgets/app_text_field.dart';
import '../application/bill_draft_provider.dart';
import '../domain/bill_amount.dart';

class PaymentDetailsSection extends ConsumerStatefulWidget {
  const PaymentDetailsSection({super.key});

  @override
  ConsumerState<PaymentDetailsSection> createState() =>
      _PaymentDetailsSectionState();
}

class _PaymentDetailsSectionState extends ConsumerState<PaymentDetailsSection> {
  final _previousRemainingController = TextEditingController();
  final _advancePaymentController = TextEditingController();

  @override
  void dispose() {
    _previousRemainingController.dispose();
    _advancePaymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);
    _syncController(_previousRemainingController, draft.previousRemainingInput);
    _syncController(_advancePaymentController, draft.advancePaymentInput);

    return AppFieldGroup(
      title: 'Payment Details (Optional)',
      icon: Icons.account_balance_wallet_outlined,
      children: [
        AppTextField(
          key: const ValueKey('previous-remaining-input'),
          label: 'Previous Remaining (optional)',
          hint: 'PKR 0.00',
          controller: _previousRemainingController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [DecimalInputFormatter()],
          validator: _validateAmount,
          onChanged: ref
              .read(billDraftProvider.notifier)
              .updatePreviousRemaining,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const ValueKey('advance-payment-input'),
          label: 'Advance Payment (optional)',
          hint: 'PKR 0.00',
          controller: _advancePaymentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.left,
          inputFormatters: [DecimalInputFormatter()],
          validator: _validateAmount,
          onChanged: ref.read(billDraftProvider.notifier).updateAdvancePayment,
        ),
      ],
    );
  }

  String? _validateAmount(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty || BillAmount.parsePaisa(input) != null) return null;
    return 'Enter a non-negative amount with up to 2 decimal places.';
  }

  void _syncController(TextEditingController controller, String text) {
    if (controller.text == text) return;
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
