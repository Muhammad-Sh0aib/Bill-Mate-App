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

    await db.insert('bills', {
      'id': 'legacy-bill',
      'customer_name': 'Legacy customer',
      'bill_date': '2026-01-01',
      'company_name_snapshot': 'Legacy workshop',
      'company_phone_snapshot': '0300',
      'original_subtotal_paisa': 10000,
      'total_item_discounts_paisa': 0,
      'subtotal_after_item_discounts_paisa': 10000,
      'bill_discount_type': 'none',
      'bill_discount_amount_paisa': 0,
      'final_payable_paisa': 10000,
      'created_at': '2026-01-01T00:00:00.000Z',
      'updated_at': '2026-01-01T00:00:00.000Z',
    });

    await DatabaseSchema.upgrade(db);

    final columns = await db.rawQuery('PRAGMA table_info(bills)');
    final columnNames = columns.map((column) => column['name']).toSet();
    expect(
      columnNames,
      containsAll([
        'bill_number',
        'status',
        'previous_remaining_paisa',
        'advance_payment_paisa',
      ]),
    );
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        ['company_settings'],
      ),
      hasLength(1),
    );
    final migratedBill = (await db.query(
      'bills',
      where: 'id = ?',
      whereArgs: ['legacy-bill'],
    )).single;
    expect(migratedBill['previous_remaining_paisa'], 0);
    expect(migratedBill['advance_payment_paisa'], 0);
  });
}
