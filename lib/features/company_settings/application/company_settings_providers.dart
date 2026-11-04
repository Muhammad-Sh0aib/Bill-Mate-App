import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_settings_repository.dart';
import '../domain/company_details.dart';

final companySettingsRepositoryProvider = Provider<CompanySettingsRepository>(
  (ref) => SharedPreferencesCompanySettingsRepository(),
);

final companySettingsProvider = FutureProvider<CompanyDetails>((ref) {
  return ref.watch(companySettingsRepositoryProvider).load();
});
