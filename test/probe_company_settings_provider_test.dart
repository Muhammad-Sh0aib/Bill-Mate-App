import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/features/bills/application/bill_draft_provider.dart';
import 'package:bill_mate/features/company_settings/application/company_settings_providers.dart';
import 'package:bill_mate/features/company_settings/domain/company_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  test('provider refresh updates bill snapshot', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final repo = container.read(companySettingsRepositoryProvider);
    const details = CompanyDetails(
      name: 'Atlas Workshop',
      phone: '0300-0000000',
    );
    await repo.save(details);

    final draft = container.read(billDraftProvider);
    expect(draft.companySnapshot.name, isNot('Atlas Workshop'));

    container.read(billDraftProvider.notifier).updateCompanySnapshot(details);
    expect(
      container.read(billDraftProvider).companySnapshot.name,
      'Atlas Workshop',
    );

    final refreshed = await container.refresh(companySettingsProvider.future);
    expect(refreshed.name, 'Atlas Workshop');
    container.read(billDraftProvider.notifier).updateCompanySnapshot(refreshed);
    expect(
      container.read(billDraftProvider).companySnapshot.name,
      'Atlas Workshop',
    );
  });
}
