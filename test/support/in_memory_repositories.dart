import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/features/bills/data/bill_repository.dart';
import 'package:bill_mate/features/company_settings/data/company_settings_repository.dart';
import 'package:bill_mate/features/company_settings/domain/company_details.dart';

class EmptyBillRepository extends BillRepository {
  @override
  Future<List<BillRecord>> listRecentBills({int limit = 7}) async => const [];

  @override
  Future<int> countCompletedBills() async => 0;

  @override
  Future<List<BillRecord>> searchBills(String query) async => const [];
}

class MemoryCompanySettingsRepository implements CompanySettingsRepository {
  CompanyDetails _details = const CompanyDetails(
    name: AppConfig.defaultCompanyName,
    phone: AppConfig.defaultCompanyPhone,
  );

  @override
  Future<CompanyDetails> load() async => _details;

  @override
  Future<void> save(CompanyDetails details) async {
    _details = details;
  }
}
