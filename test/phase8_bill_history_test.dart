import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/core/database/database_service.dart';
import 'package:bill_mate/features/bills/data/bill_repository.dart';
import 'package:bill_mate/features/bills/domain/bill_discount.dart';
import 'package:bill_mate/features/bills/domain/bill_item.dart';
import 'package:bill_mate/features/bills/domain/bill_totals.dart';

void main() {
  late BillRepository repository;

  setUp(() async {
    databaseFactory = databaseFactoryFfi;
    repository = BillRepository();
    final db = await DatabaseService.instance.database;
    await db.transaction((transaction) async {
      await transaction.delete(
        'bill_items',
        where: 'bill_id LIKE ?',
        whereArgs: ['phase8-%'],
      );
      await transaction.delete(
        'bills',
        where: 'id LIKE ?',
        whereArgs: ['phase8-%'],
      );
      await transaction.delete(
        'drafts',
        where: 'id LIKE ?',
        whereArgs: ['phase8-%'],
      );
    });
  });

  test(
    'latest-seven uses creation time and search includes retained older bills',
    () async {
      for (var index = 0; index < 8; index++) {
        await _saveBill(
          repository,
          id: 'phase8-history-$index',
          customerName: 'Customer $index',
        );
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }

      final latest = await repository.listRecentBills();
      expect(latest, hasLength(7));
      expect(latest.first.id, 'phase8-history-7');
      expect(
        latest.map((bill) => bill.id),
        isNot(contains('phase8-history-0')),
      );
      expect(await repository.countCompletedBills(), greaterThanOrEqualTo(8));

      final olderMatch = await repository.searchBills('cUsToMeR 0');
      expect(olderMatch.map((bill) => bill.id), ['phase8-history-0']);
      expect(olderMatch.single.items.single.amountInput, '12.34');
      expect(await repository.searchBills('phase8-history-0'), hasLength(1));
    },
  );

  test(
    'editing preserves bill ID and creation timestamp without duplicating',
    () async {
      const billId = 'phase8-edit-preserves-created';
      await _saveBill(repository, id: billId, customerName: 'Before Edit');
      final db = await DatabaseService.instance.database;
      final original = (await db.query(
        'bills',
        columns: ['created_at'],
        where: 'id = ?',
        whereArgs: [billId],
      )).single['created_at'];
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await _saveBill(
        repository,
        id: billId,
        customerName: 'After Edit',
        amountInput: '99.75',
      );

      final saved = await repository.loadById(billId);
      final updated = (await db.query(
        'bills',
        columns: ['created_at', 'updated_at'],
        where: 'id = ?',
        whereArgs: [billId],
      )).single;
      expect(saved?.customerName, 'After Edit');
      expect(saved?.items.single.amountInput, '99.75');
      expect(updated['created_at'], original);
      expect(updated['updated_at'], isNot(original));
      expect(
        await db
            .rawQuery('SELECT COUNT(*) AS count FROM bills WHERE id = ?', [
              billId,
            ])
            .then(Sqflite.firstIntValue),
        1,
      );
    },
  );

  test('deletion removes only the target bill and items, not drafts', () async {
    await _saveBill(
      repository,
      id: 'phase8-delete-target',
      customerName: 'Delete Target',
    );
    await _saveBill(
      repository,
      id: 'phase8-delete-keep',
      customerName: 'Keep Target',
    );
    final db = await DatabaseService.instance.database;
    await db.insert('drafts', {
      'id': 'phase8-unrelated-draft',
      'customer_name': 'Draft Customer',
      'bill_date': '2026-01-01',
      'company_name_snapshot': 'Workshop',
      'company_phone_snapshot': '03000000000',
      'payload': '{}',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': 1,
    });

    expect(await repository.deleteBill('phase8-delete-target'), isTrue);
    expect(await repository.deleteBill('phase8-delete-target'), isFalse);
    expect(await repository.loadById('phase8-delete-target'), isNull);
    expect(await repository.loadById('phase8-delete-keep'), isNotNull);
    expect(
      await db.query(
        'bill_items',
        where: 'bill_id = ?',
        whereArgs: ['phase8-delete-target'],
      ),
      isEmpty,
    );
    expect(
      await db.query(
        'drafts',
        where: 'id = ?',
        whereArgs: ['phase8-unrelated-draft'],
      ),
      hasLength(1),
    );
  });
}

Future<void> _saveBill(
  BillRepository repository, {
  required String id,
  required String customerName,
  String amountInput = '12.34',
}) async {
  final items = [
    BillItem(
      id: '$id-item',
      description: 'Repair service',
      amountInput: amountInput,
    ),
  ];
  final totals = const BillTotalsCalculator().calculate(
    items: items,
    billDiscount: const BillDiscount(),
  );
  await repository.saveCompletedBill(
    billId: id,
    customerName: customerName,
    billDate: DateTime(2026, 10, 12),
    companyNameSnapshot: 'Workshop Snapshot',
    companyPhoneSnapshot: '0300-2246183',
    companyAddressSnapshot: null,
    items: items,
    billDiscount: const BillDiscount(),
    totals: totals,
    billNumber: 'BN-$id',
  );
}
