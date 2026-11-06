import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/utils/date_utils.dart';
import '../../company_settings/application/company_settings_providers.dart';
import '../../company_settings/domain/company_details.dart';
import '../data/bill_repository.dart';
import '../domain/bill_discount.dart';
import '../domain/bill_draft.dart';
import '../domain/bill_item.dart';

typedef BillTodayProvider = DateTime Function();

final billTodayProvider = Provider<BillTodayProvider>(
  (ref) => BillDateUtils.today,
);

final billDraftProvider = NotifierProvider<BillDraftController, BillDraft>(
  BillDraftController.new,
);

class BillDraftController extends Notifier<BillDraft> {
  late DateTime _initialDate;
  bool _hasExplicitCompanySnapshot = false;

  @override
  BillDraft build() {
    final todayProvider = ref.watch(billTodayProvider);
    _initialDate = _dateOnly(todayProvider());
    final savedCompany = ref.read(companySettingsProvider).asData?.value;
    ref.listen(companySettingsProvider, (previous, next) {
      next.whenData((details) {
        if (!_hasExplicitCompanySnapshot) {
          _applyCompanySnapshot(details);
        }
      });
    });
    return _newDraft(_initialDate, savedCompany ?? _defaultCompany);
  }

  CompanyDetails get _defaultCompany => const CompanyDetails(
    name: AppConfig.defaultCompanyName,
    phone: AppConfig.defaultCompanyPhone,
  );

  void updateCustomerName(String customerName) {
    if (customerName == state.customerName) return;
    state = state.copyWith(
      customerName: customerName,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: customerName,
        billDate: state.billDate,
        items: state.items,
        billDiscount: state.billDiscount,
      ),
    );
  }

  bool updateBillDate(DateTime billDate) {
    final selectedDate = _dateOnly(billDate);
    final todayProvider = ref.read(billTodayProvider);
    final today = _dateOnly(todayProvider());
    if (selectedDate.isAfter(today) || selectedDate.isBefore(DateTime(1))) {
      return false;
    }
    state = state.copyWith(
      billDate: selectedDate,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: selectedDate,
        items: state.items,
        billDiscount: state.billDiscount,
      ),
    );
    return true;
  }

  BillItem addItem() {
    final item = BillItem.empty();
    final items = [...state.items, item];
    state = state.copyWith(
      items: items,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: items,
        billDiscount: state.billDiscount,
      ),
    );
    return item;
  }

  void updateItemDescription(String itemId, String description) {
    _updateItem(itemId, (item) => item.copyWith(description: description));
  }

  void updateItemAmount(String itemId, String amountInput) {
    _updateItem(itemId, (item) => item.copyWith(amountInput: amountInput));
  }

  void updateItemDiscount(String itemId, BillDiscount discount) {
    _updateItem(itemId, (item) => item.copyWith(discount: discount));
  }

  void updateBillDiscount(BillDiscount billDiscount) {
    if (state.billDiscount == billDiscount) return;
    state = state.copyWith(
      billDiscount: billDiscount,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: state.items,
        billDiscount: billDiscount,
      ),
    );
  }

  void updatePreviousRemaining(String amountInput) {
    if (state.previousRemainingInput == amountInput) return;
    state = state.copyWith(
      previousRemainingInput: amountInput,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: state.items,
        billDiscount: state.billDiscount,
        previousRemainingInput: amountInput,
      ),
    );
  }

  void updateAdvancePayment(String amountInput) {
    if (state.advancePaymentInput == amountInput) return;
    state = state.copyWith(
      advancePaymentInput: amountInput,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: state.items,
        billDiscount: state.billDiscount,
        advancePaymentInput: amountInput,
      ),
    );
  }

  void deleteItem(String itemId) {
    final items = state.items.where((item) => item.id != itemId).toList();
    if (items.length == state.items.length) return;
    state = state.copyWith(
      items: items,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: items,
        billDiscount: state.billDiscount,
      ),
    );
  }

  void _updateItem(String itemId, BillItem Function(BillItem) update) {
    final index = state.items.indexWhere((item) => item.id == itemId);
    if (index < 0) return;
    final items = [...state.items];
    final updated = update(items[index]);
    if (updated.description == items[index].description &&
        updated.amountInput == items[index].amountInput &&
        updated.discount == items[index].discount) {
      return;
    }
    items[index] = updated;
    state = state.copyWith(
      items: items,
      hasUnsavedChanges: _hasDraftChanges(
        customerName: state.customerName,
        billDate: state.billDate,
        items: items,
        billDiscount: state.billDiscount,
      ),
    );
  }

  bool _hasDraftChanges({
    required String customerName,
    required DateTime billDate,
    required List<BillItem> items,
    required BillDiscount billDiscount,
    String? previousRemainingInput,
    String? advancePaymentInput,
  }) {
    return customerName.isNotEmpty ||
        !_sameDate(billDate, _initialDate) ||
        items.isNotEmpty ||
        !billDiscount.isNone ||
        (previousRemainingInput ?? state.previousRemainingInput).isNotEmpty ||
        (advancePaymentInput ?? state.advancePaymentInput).isNotEmpty;
  }

  void updateCompanySnapshot(CompanyDetails details) {
    _hasExplicitCompanySnapshot = true;
    _applyCompanySnapshot(details);
  }

  void _applyCompanySnapshot(CompanyDetails details) {
    final snapshot = CompanyInfoSnapshot.fromSettings(details);
    state = state.copyWith(companySnapshot: snapshot);
  }

  void refreshDateIfUntouched() {
    final todayProvider = ref.read(billTodayProvider);
    final today = _dateOnly(todayProvider());
    if (state.hasUnsavedChanges || !_sameDate(state.billDate, _initialDate)) {
      return;
    }
    if (_sameDate(today, _initialDate)) return;

    _initialDate = today;
    state = state.copyWith(billDate: today);
  }

  void reset({CompanyDetails? company}) {
    final todayProvider = ref.read(billTodayProvider);
    _initialDate = _dateOnly(todayProvider());
    _hasExplicitCompanySnapshot = false;
    state = _newDraft(_initialDate, company ?? _defaultCompany);
  }

  void loadSavedBill(BillRecord bill) {
    _initialDate = _dateOnly(bill.billDate);
    _hasExplicitCompanySnapshot = true;
    state = BillDraft(
      id: bill.id,
      customerName: bill.customerName,
      billDate: _initialDate,
      companySnapshot: CompanyInfoSnapshot(
        name: bill.companyNameSnapshot,
        phone: bill.companyPhoneSnapshot,
      ),
      createdAt: bill.createdAt,
      hasUnsavedChanges: false,
      billDiscount: bill.billDiscount,
      previousRemainingInput: bill.previousRemainingInPaisa == BigInt.zero
          ? ''
          : _amountInputFromPaisa(bill.previousRemainingInPaisa),
      advancePaymentInput: bill.advancePaymentInPaisa == BigInt.zero
          ? ''
          : _amountInputFromPaisa(bill.advancePaymentInPaisa),
      items: bill.items,
    );
  }

  void markSaved() {
    state = state.copyWith(hasUnsavedChanges: false);
  }

  String _amountInputFromPaisa(BigInt paisa) {
    final rupees = paisa ~/ BigInt.from(100);
    final remainder = (paisa % BigInt.from(100)).toString().padLeft(2, '0');
    return '$rupees.$remainder';
  }

  BillDraft _newDraft(DateTime date, CompanyDetails company) {
    return BillDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerName: '',
      billDate: date,
      companySnapshot: CompanyInfoSnapshot.fromSettings(company),
      createdAt: DateTime.now(),
      hasUnsavedChanges: false,
      billDiscount: const BillDiscount(),
      items: const [],
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
