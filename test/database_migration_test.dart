import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/core/database/database_schema.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upgrade adds saved-bill columns to a version 1 database', () async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE bills (
              id TEXT PRIMARY KEY,
              customer_name TEXT NOT NULL,
              bill_date TEXT NOT NULL,
              company_name_snapshot TEXT NOT NULL,
              company_phone_snapshot TEXT NOT NULL,
              company_address_snapshot TEXT,
              original_subtotal_paisa INTEGER NOT NULL,
              total_item_discounts_paisa INTEGER NOT NULL,
              subtotal_after_item_discounts_paisa INTEGER NOT NULL,
              bill_discount_type TEXT NOT NULL,
              bill_discount_value TEXT,
              bill_discount_amount_paisa INTEGER NOT NULL,
              final_payable_paisa INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    addTearDown(db.close);

    await DatabaseSchema.upgrade(db);

    final columns = await db.rawQuery('PRAGMA table_info(bills)');
    final columnNames = columns.map((column) => column['name']).toSet();
    expect(columnNames, containsAll(['bill_number', 'status']));
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        ['company_settings'],
      ),
      hasLength(1),
    );
  });
}
