import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_confirm_dialog.dart';
import '../../company_settings/application/company_settings_providers.dart';
import '../application/bill_draft_provider.dart';

Future<bool> confirmBillDraftExit(BuildContext context, WidgetRef ref) async {
  final draft = ref.read(billDraftProvider);
  final settings = ref.read(companySettingsProvider).asData?.value;
  if (!draft.hasUnsavedChanges) {
    ref.read(billDraftProvider.notifier).reset(company: settings);
    return true;
  }

  final discard = await showAppConfirmDialog(
    context,
    title: 'Discard changes?',
    message: 'The current bill details have not been saved.',
    cancelLabel: 'Keep Editing',
    confirmLabel: 'Discard',
    isDestructive: true,
  );
  if (discard != true) return false;

  ref.read(billDraftProvider.notifier).reset(company: settings);
  return true;
}
