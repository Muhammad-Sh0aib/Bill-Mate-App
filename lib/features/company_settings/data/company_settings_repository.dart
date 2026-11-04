import 'package:sqflite/sqflite.dart';

import '../../../app/config/app_config.dart';
import '../../../core/database/database_service.dart';
import '../domain/company_details.dart';

abstract interface class CompanySettingsRepository {
  Future<CompanyDetails> load();

  Future<void> save(CompanyDetails details);
}

class SharedPreferencesCompanySettingsRepository
    implements CompanySettingsRepository {
  SharedPreferencesCompanySettingsRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  @override
  Future<CompanyDetails> load() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'company_settings',
      limit: 1,
      orderBy: 'updated_at DESC',
    );
    if (rows.isEmpty) {
      return const CompanyDetails(
        name: AppConfig.defaultCompanyName,
        phone: AppConfig.defaultCompanyPhone,
      );
    }
    final row = rows.first;
    final name =
        (row['company_name'] as String?)?.trim() ??
        AppConfig.defaultCompanyName;
    final phone =
        (row['company_phone'] as String?)?.trim() ??
        AppConfig.defaultCompanyPhone;
    return CompanyDetails(name: name, phone: phone);
  }

  @override
  Future<void> save(CompanyDetails details) async {
    final db = await _databaseService.database;
    final name = details.name.trim();
    final phone = details.phone.trim();
    if (name.isEmpty || phone.isEmpty) {
      throw StateError('Company details cannot be empty.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': 1,
      'company_name': name,
      'company_phone': phone,
      'updated_at': now,
    };

    final inserted = await db.insert(
      'company_settings',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (inserted == 0) {
      throw StateError('Company details were not saved.');
    }
  }
}
