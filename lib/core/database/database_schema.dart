import 'package:sqflite/sqflite.dart';

abstract class DatabaseSchema {
  DatabaseSchema._();

  static const String companySettingsTable = 'company_settings';
  static const String billsTable = 'bills';
  static const String billItemsTable = 'bill_items';
  static const String draftsTable = 'drafts';

  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $companySettingsTable (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        company_name TEXT NOT NULL,
        company_phone TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $billsTable (
        id TEXT PRIMARY KEY,
        bill_number TEXT,
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
        previous_remaining_paisa INTEGER NOT NULL DEFAULT 0,
        advance_payment_paisa INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $billItemsTable (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        description TEXT NOT NULL,
        amount_paisa INTEGER NOT NULL,
        discount_type TEXT NOT NULL,
        discount_value TEXT,
        discount_amount_paisa INTEGER NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES $billsTable(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $draftsTable (
        id TEXT PRIMARY KEY,
        customer_name TEXT NOT NULL,
        bill_date TEXT NOT NULL,
        company_name_snapshot TEXT NOT NULL,
        company_phone_snapshot TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bills_updated_at ON $billsTable(updated_at)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON $billItemsTable(bill_id, sort_order)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_drafts_updated_at ON $draftsTable(updated_at DESC)',
    );

    final defaults = await db.query(companySettingsTable, limit: 1);
    if (defaults.isEmpty) {
      await db.insert(companySettingsTable, {
        'id': 1,
        'company_name': 'Babar Machnical Work',
        'company_phone': '0300-2246183',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  static Future<void> upgrade(Database db) async {
    await create(db);
    await _ensureColumn(db, billsTable, 'bill_number', 'TEXT');
    await _ensureColumn(
      db,
      billsTable,
      'status',
      "TEXT NOT NULL DEFAULT 'completed'",
    );
    await _ensureColumn(
      db,
      billsTable,
      'previous_remaining_paisa',
      'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      billsTable,
      'advance_payment_paisa',
      'INTEGER NOT NULL DEFAULT 0',
    );
  }

  static Future<void> _ensureColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((entry) => entry['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}
