import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/database/database_service.dart';
import '../../core/errors/app_exception.dart';
import '../bills/domain/bill_discount.dart';
import '../bills/domain/bill_draft.dart';
import '../bills/domain/bill_item.dart';

class DraftRepository {
  DraftRepository({DatabaseService? databaseService})
    : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  Future<void> upsertDraft(BillDraft draft) async {
    final db = await _databaseService.database;
    final payload = jsonEncode({
      'version': 1,
      'customer_name': draft.customerName,
      'bill_date': draft.billDate.toIso8601String(),
      'company_name': draft.companySnapshot.name,
      'company_phone': draft.companySnapshot.phone,
      'bill_discount': {
        'type': draft.billDiscount.type.name,
        'fixed_input': draft.billDiscount.fixedInput,
        'percentage_input': draft.billDiscount.percentageInput,
      },
      'items': draft.items
          .map(
            (item) => {
              'id': item.id,
              'description': item.description,
              'amount_input': item.amountInput,
              'discount': {
                'type': item.discount.type.name,
                'fixed_input': item.discount.fixedInput,
                'percentage_input': item.discount.percentageInput,
              },
            },
          )
          .toList(),
    });

    await db.insert('drafts', {
      'id': draft.id,
      'customer_name': draft.customerName,
      'bill_date': draft.billDate.toUtc().toIso8601String().split('T').first,
      'company_name_snapshot': draft.companySnapshot.name,
      'company_phone_snapshot': draft.companySnapshot.phone,
      'payload': payload,
      'created_at': draft.createdAt.toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<BillDraft?> loadActiveDraft() async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'drafts',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final payload = row['payload'] as String?;
    if (payload == null || payload.isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        throw const FormatException('Draft payload is not a JSON object.');
      }
      final data = decoded as Map<String, dynamic>;
      final items = (data['items'] as List? ?? const [])
          .map(
            (entry) =>
                _draftItemFromMap(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();
      final billDiscount = _discountFromMap(
        Map<String, dynamic>.from(data['bill_discount'] as Map? ?? const {}),
      );
      final customerName = (data['customer_name'] as String?) ?? '';
      final billDateIso =
          data['bill_date'] as String? ?? DateTime.now().toIso8601String();
      final companyName = (data['company_name'] as String?) ?? '';
      final companyPhone = (data['company_phone'] as String?) ?? '';

      return BillDraft(
        id: row['id'] as String,
        customerName: customerName,
        billDate: DateTime.parse(billDateIso),
        companySnapshot: CompanyInfoSnapshot(
          name: companyName,
          phone: companyPhone,
        ),
        createdAt: DateTime.parse(row['created_at'] as String),
        hasUnsavedChanges: false,
        billDiscount: billDiscount,
        items: items,
      );
    } catch (_) {
      throw const StorageException('Draft data could not be restored.');
    }
  }

  Future<void> deleteDraft(String draftId) async {
    final db = await _databaseService.database;
    await db.delete('drafts', where: 'id = ?', whereArgs: [draftId]);
  }

  BillItem _draftItemFromMap(Map<String, dynamic> entry) {
    final rawDiscount = entry['discount'];
    final discountMap = rawDiscount is Map
        ? Map<String, dynamic>.from(rawDiscount)
        : const <String, dynamic>{};
    final discount = _discountFromMap(discountMap);
    return BillItem(
      id:
          (entry['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      description: (entry['description'] as String?) ?? '',
      amountInput: (entry['amount_input'] as String?) ?? '',
      discount: discount,
    );
  }

  BillDiscount _discountFromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'none';
    final fixedInput = map['fixed_input'] as String? ?? '';
    final percentageInput = map['percentage_input'] as String? ?? '';

    switch (typeName) {
      case 'fixed':
        return BillDiscount(type: DiscountType.fixed, fixedInput: fixedInput);
      case 'percentage':
        return BillDiscount(
          type: DiscountType.percentage,
          percentageInput: percentageInput,
        );
      case 'none':
      default:
        return const BillDiscount();
    }
  }
}
