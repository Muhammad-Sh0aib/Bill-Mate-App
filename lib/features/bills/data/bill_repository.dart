import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import '../domain/bill_discount.dart';
import '../domain/bill_item.dart';
import '../domain/bill_totals.dart';

class BillRecord {
  BillRecord({
    required this.id,
    required this.billNumber,
    required this.customerName,
    required this.billDate,
    required this.companyNameSnapshot,
    required this.companyPhoneSnapshot,
    required this.companyAddressSnapshot,
    required this.originalSubtotalInPaisa,
    required this.totalItemDiscountInPaisa,
    required this.subtotalAfterItemDiscountsInPaisa,
    required this.billDiscount,
    required this.billDiscountAmountInPaisa,
    required this.finalPayableInPaisa,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    BigInt? previousRemainingInPaisa,
    BigInt? advancePaymentInPaisa,
  }) : previousRemainingInPaisa = previousRemainingInPaisa ?? BigInt.zero,
       advancePaymentInPaisa = advancePaymentInPaisa ?? BigInt.zero;

  final String id;
  final String? billNumber;
  final String customerName;
  final DateTime billDate;
  final String companyNameSnapshot;
  final String companyPhoneSnapshot;
  final String? companyAddressSnapshot;
  final BigInt originalSubtotalInPaisa;
  final BigInt totalItemDiscountInPaisa;
  final BigInt subtotalAfterItemDiscountsInPaisa;
  final BillDiscount billDiscount;
  final BigInt billDiscountAmountInPaisa;
  final BigInt finalPayableInPaisa;
  final BigInt previousRemainingInPaisa;
  final BigInt advancePaymentInPaisa;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BillItem> items;
}

class BillRepository {
  BillRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<void> saveCompletedBill({
    required String billId,
    required String customerName,
    required DateTime billDate,
    required String companyNameSnapshot,
    required String companyPhoneSnapshot,
    required String? companyAddressSnapshot,
    required List<BillItem> items,
    required BillDiscount billDiscount,
    required BillTotals totals,
    String? billNumber,
    int previousRemainingPaisa = 0,
    int advancePaymentPaisa = 0,
  }) async {
    final db = await _databaseService.database;
    final now = DateTime.now().toUtc();
    final billDateIso = _isoDate(billDate);
    final billValue = {
      'id': billId,
      'bill_number': billNumber,
      'customer_name': customerName.trim(),
      'bill_date': billDateIso,
      'company_name_snapshot': companyNameSnapshot.trim(),
      'company_phone_snapshot': companyPhoneSnapshot.trim(),
      'company_address_snapshot': companyAddressSnapshot?.trim(),
      'original_subtotal_paisa': totals.originalSubtotalInPaisa.toInt(),
      'total_item_discounts_paisa': totals.totalItemDiscountInPaisa.toInt(),
      'subtotal_after_item_discounts_paisa': totals
          .subtotalAfterItemDiscountsInPaisa
          .toInt(),
      'bill_discount_type': billDiscount.type.name,
      'bill_discount_value': _discountValueForStorage(billDiscount),
      'bill_discount_amount_paisa': totals.billDiscountInPaisa.toInt(),
      'final_payable_paisa': totals.finalPayableInPaisa.toInt(),
      'previous_remaining_paisa': previousRemainingPaisa,
      'advance_payment_paisa': advancePaymentPaisa,
      'updated_at': now.toIso8601String(),
      'status': 'completed',
    };

    await db.transaction((txn) async {
      final existing = await txn.query(
        'bills',
        columns: ['id', 'created_at'],
        where: 'id = ?',
        whereArgs: [billId],
      );

      if (existing.isEmpty) {
        await txn.insert('bills', {
          ...billValue,
          'created_at': now.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.fail);
      } else {
        await txn.update(
          'bills',
          billValue,
          where: 'id = ?',
          whereArgs: [billId],
        );
      }

      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);

      for (var index = 0; index < items.length; index++) {
        final item = items[index];
        final amount = item.amountInPaisa ?? 0;
        final discount = item.discount;
        final itemValue = {
          'id': item.id,
          'bill_id': billId,
          'sort_order': index,
          'description': item.description.trim(),
          'amount_paisa': amount,
          'discount_type': discount.type.name,
          'discount_value': _discountValueForStorage(discount),
          'discount_amount_paisa': _discountForStorage(item, amount),
        };
        await txn.insert(
          'bill_items',
          itemValue,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<BillRecord>> listRecentBills({int limit = 7}) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'bills',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'created_at DESC, id DESC',
      limit: limit < 1 ? 1 : limit,
    );
    return _loadBillsWithItems(db, rows);
  }

  Future<int> countCompletedBills() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM bills WHERE status = ?',
      ['completed'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<BillRecord>> searchBills(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return listRecentBills();
    final escapedQuery = normalizedQuery
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final db = await _databaseService.database;
    final rows = await db.query(
      'bills',
      where: '''
        status = ? AND (
          lower(customer_name) LIKE ? ESCAPE '\\' OR
          lower(COALESCE(bill_number, '')) LIKE ? ESCAPE '\\' OR
          lower(id) LIKE ? ESCAPE '\\'
        )
      ''',
      whereArgs: [
        'completed',
        '%$escapedQuery%',
        '%$escapedQuery%',
        '%$escapedQuery%',
      ],
      orderBy: 'created_at DESC, id DESC',
    );
    return _loadBillsWithItems(db, rows);
  }

  Future<List<BillRecord>> _loadBillsWithItems(
    DatabaseExecutor db,
    List<Map<String, Object?>> rows,
  ) async {
    final bills = <BillRecord>[];
    for (final row in rows) {
      final items = await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: [row['id']],
        orderBy: 'sort_order ASC',
      );
      bills.add(_mapBill(row, items));
    }
    return bills;
  }

  Future<BillRecord?> loadById(String billId) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'bills',
      where: 'id = ? AND status = ?',
      whereArgs: [billId, 'completed'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final items = await db.query(
      'bill_items',
      where: 'bill_id = ?',
      whereArgs: [billId],
      orderBy: 'sort_order ASC',
    );
    return _mapBill(rows.first, items);
  }

  Future<bool> deleteBill(String billId) async {
    final db = await _databaseService.database;
    return db.transaction((txn) async {
      final existing = await txn.query(
        'bills',
        columns: ['id'],
        where: 'id = ? AND status = ?',
        whereArgs: [billId, 'completed'],
        limit: 1,
      );
      if (existing.isEmpty) return false;
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
      final deleted = await txn.delete(
        'bills',
        where: 'id = ? AND status = ?',
        whereArgs: [billId, 'completed'],
      );
      return deleted == 1;
    });
  }

  BillRecord _mapBill(
    Map<String, Object?> row,
    List<Map<String, Object?>> itemRows,
  ) {
    final items = itemRows.map((itemRow) {
      final discount = _discountFromStorage(
        type: itemRow['discount_type'] as String?,
        value: itemRow['discount_value'] as String?,
      );
      return BillItem(
        id: itemRow['id'] as String,
        description: itemRow['description'] as String? ?? '',
        amountInput: (itemRow['amount_paisa'] as int?) == null
            ? ''
            : _amountInputFromPaisa(itemRow['amount_paisa'] as int),
        discount: discount,
      );
    }).toList();

    return BillRecord(
      id: row['id'] as String,
      billNumber: row['bill_number'] as String?,
      customerName: row['customer_name'] as String? ?? '',
      billDate: DateTime.parse(row['bill_date'] as String),
      companyNameSnapshot: row['company_name_snapshot'] as String? ?? '',
      companyPhoneSnapshot: row['company_phone_snapshot'] as String? ?? '',
      companyAddressSnapshot: row['company_address_snapshot'] as String?,
      originalSubtotalInPaisa: BigInt.from(
        row['original_subtotal_paisa'] as int? ?? 0,
      ),
      totalItemDiscountInPaisa: BigInt.from(
        row['total_item_discounts_paisa'] as int? ?? 0,
      ),
      subtotalAfterItemDiscountsInPaisa: BigInt.from(
        row['subtotal_after_item_discounts_paisa'] as int? ?? 0,
      ),
      billDiscount: _discountFromStorage(
        type: row['bill_discount_type'] as String?,
        value: row['bill_discount_value'] as String?,
      ),
      billDiscountAmountInPaisa: BigInt.from(
        row['bill_discount_amount_paisa'] as int? ?? 0,
      ),
      finalPayableInPaisa: BigInt.from(row['final_payable_paisa'] as int? ?? 0),
      previousRemainingInPaisa: BigInt.from(
        row['previous_remaining_paisa'] as int? ?? 0,
      ),
      advancePaymentInPaisa: BigInt.from(
        row['advance_payment_paisa'] as int? ?? 0,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      items: items,
    );
  }

  String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _amountInputFromPaisa(int paisa) {
    final amount = BigInt.from(paisa);
    final rupees = amount ~/ BigInt.from(100);
    final remainder = (amount % BigInt.from(100)).toString().padLeft(2, '0');
    return '$rupees.$remainder';
  }

  String? _discountValueForStorage(BillDiscount discount) {
    switch (discount.type) {
      case DiscountType.none:
        return null;
      case DiscountType.fixed:
        return discount.fixedInput.trim().isEmpty
            ? null
            : discount.fixedInput.trim();
      case DiscountType.percentage:
        return discount.percentageInput.trim().isEmpty
            ? null
            : discount.percentageInput.trim();
    }
  }

  BillDiscount _discountFromStorage({
    required String? type,
    required String? value,
  }) {
    switch (type ?? 'none') {
      case 'fixed':
        return BillDiscount(type: DiscountType.fixed, fixedInput: value ?? '');
      case 'percentage':
        return BillDiscount(
          type: DiscountType.percentage,
          percentageInput: value ?? '',
        );
      case 'none':
      default:
        return const BillDiscount();
    }
  }

  int _discountForStorage(BillItem item, int amount) {
    final discount = item.discount;
    if (discount.type == DiscountType.none) return 0;
    if (discount.type == DiscountType.fixed) {
      return discount.fixedPaisa ?? 0;
    }
    if (amount <= 0) return 0;
    final percent = discount.percentageBasisPoints ?? 0;
    final numerator = BigInt.from(amount) * BigInt.from(percent);
    final quotient = numerator ~/ BigInt.from(10000);
    final remainder = numerator % BigInt.from(10000);
    if (remainder * BigInt.two >= BigInt.from(10000)) {
      return (quotient + BigInt.one).toInt();
    }
    return quotient.toInt();
  }
}
