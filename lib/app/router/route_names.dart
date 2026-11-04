/// Route path constants and named-route identifiers for BillMate.
///
/// Use these constants everywhere; never write a raw route string
/// directly in a widget or another file.
abstract class RouteNames {
  RouteNames._();

  // ── Primary Tab Paths ──────────────────────────────────────────
  static const String home = '/home';
  static const String root = '/';
  static const String newBill = '/new-bill';
  static const String legacyNewBill = '/bills/new';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String editSavedBill = '/new-bill/edit/:billId';
  static const String billDetails = '/history/:billId';
  static const String billPreview = '/bill-preview';
  static const String smartVoiceEntry = '/smart-voice-entry';

  // ── Named-route identifiers ───────────────────────────────────
  static const String homeName = 'home';
  static const String newBillName = 'new-bill';
  static const String historyName = 'history';
  static const String settingsName = 'settings';
  static const String editSavedBillName = 'edit-saved-bill';
  static const String billDetailsName = 'bill-details';
  static const String billPreviewName = 'bill-preview';
  static const String smartVoiceEntryName = 'smart-voice-entry';
}
