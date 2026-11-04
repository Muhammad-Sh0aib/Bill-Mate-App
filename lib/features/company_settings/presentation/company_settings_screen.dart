import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/app_config.dart';
import '../../../app/router/route_names.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/errors/error_handler.dart';
import '../../../core/widgets/app_app_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field_group.dart';
import '../../../core/widgets/app_inline_message.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../bills/application/bill_draft_provider.dart';
import '../application/company_settings_providers.dart';
import '../domain/company_details.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key, this.returnToBill = false});

  final bool returnToBill;

  @override
  ConsumerState<CompanySettingsScreen> createState() =>
      _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _companyNameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;
  bool _hasEdited = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController(
      text: AppConfig.defaultCompanyName,
    );
    _phoneController = TextEditingController(
      text: AppConfig.defaultCompanyPhone,
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _applyLoadedSettings(CompanyDetails details) {
    if (_hasEdited) return;
    _companyNameController.value = TextEditingValue(
      text: details.name,
      selection: TextSelection.collapsed(offset: details.name.length),
    );
    _phoneController.value = TextEditingValue(
      text: details.phone,
      selection: TextSelection.collapsed(offset: details.phone.length),
    );
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final details = CompanyDetails(
      name: _companyNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    try {
      await ref.read(companySettingsRepositoryProvider).save(details);
      ref.read(billDraftProvider.notifier).updateCompanySnapshot(details);
      ref.invalidate(companySettingsProvider);
      _hasEdited = false;
      if (!mounted) return;
      if (widget.returnToBill) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details saved. Go back to update the bill.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company details saved on this device.')),
      );
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'Saving company details');
      if (!mounted) return;
      setState(
        () => _saveError = 'Company details could not be saved. Try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(companySettingsProvider, (previous, next) {
      next.whenData(_applyLoadedSettings);
    });
    final settings = ref.watch(companySettingsProvider);
    settings.whenData(_applyLoadedSettings);

    return Scaffold(
      appBar: AppAppBar(
        title: 'Settings',
        subtitle: 'Workshop Details & Preferences',
        showBackButton: widget.returnToBill,
        onBack: widget.returnToBill
            ? () {
                ref.read(billDraftProvider.notifier).refreshDateIfUntouched();
                context.go(RouteNames.newBill);
              }
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          children: [
            const AppInlineMessage(
              type: AppInlineMessageType.info,
              title: 'Workshop Information',
              message: 'These details appear on new bills and are saved on this device.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Form(
              key: _formKey,
              child: AppFieldGroup(
                title: 'Company Details',
                subtitle: 'Current details for new workshop bills',
                icon: Icons.business_rounded,
                children: [
                  AppTextField(
                    label: 'Company Name',
                    controller: _companyNameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    onChanged: (_) => _hasEdited = true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a company name.'
                        : null,
                  ),
                  AppTextField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    isRequired: true,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a phone number.'
                        : null,
                    onChanged: (_) => _hasEdited = true,
                  ),
                  const AppTextField(
                    label: 'Currency',
                    initialValue:
                        '${AppConfig.currencyCode} (${AppConfig.currencySymbol})',
                    readOnly: true,
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                ],
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppInlineMessage(
                type: AppInlineMessageType.error,
                title: 'Unable to save',
                message: _saveError!,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Save Company Details',
              icon: Icons.save_outlined,
              loading: _isSaving,
              onPressed: settings.isLoading || _isSaving ? null : _saveSettings,
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppFieldGroup(
              title: 'Application Information',
              icon: Icons.info_outline_rounded,
              children: [
                _SettingsInfo(label: 'Application', value: AppConfig.appName),
                _SettingsInfo(
                  label: 'Currency',
                  value: 'PKR (Pakistani Rupee)',
                ),
                _SettingsInfo(
                  label: 'Storage',
                  value: 'Local-only on this device',
                ),
                _SettingsInfo(
                  label: 'Workshop Focus',
                  value: 'Offset Printing Press Machinery',
                ),
              ],
            ),
            if (settings.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              const AppInlineMessage(
                type: AppInlineMessageType.error,
                title: 'Unable to load settings',
                message: 'Default company details are shown. Retry loading settings.',
              ),
              TextButton.icon(
                onPressed: () => ref.invalidate(companySettingsProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsInfo extends StatelessWidget {
  const _SettingsInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.md),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
