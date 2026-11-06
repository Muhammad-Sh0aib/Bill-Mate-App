/// BillMate application configuration.
///
/// Contains compile-time defaults. These values are intentionally
/// kept separate from user-persisted settings so that Phase 7 can
/// introduce a settings repository that overrides them without
/// changing this file.
library;

class AppConfig {
  AppConfig._();

  // ── App identity ──────────────────────────────────────────────
  static const String appName = 'BillMate';
  static const String appTagline = 'Smart Billing for Mechanical Workshops';
  static const String appVersion = '1.0.0';

  // ── Default company information ───────────────────────────────
  /// The exact name as supplied by the client. Do NOT correct spelling.
  static const String defaultCompanyName = 'Babar Machnical Work';
  static const String defaultCompanyPhone = '0300-2246183';

  // ── Currency ──────────────────────────────────────────────────
  /// ISO 4217 currency code used throughout the app.
  static const String currencyCode = 'PKR';

  /// Symbol displayed on bills and in the UI.
  static const String currencySymbol = 'Rs.';

  // ── Locale ────────────────────────────────────────────────────
  /// Default locale for formatting. Urdu ('ur') support is planned for
  /// a future localization phase.
  static const String defaultLocale = 'en_PK';
}

class DeveloperBranding {
  DeveloperBranding._();

  static const String name = 'Muhammad Shoaib';
  static const String phoneNumber = '0315 1080450';
  static const String telephoneLink = 'tel:03151080450';
  static const String developedBy = 'Developed by $name';
  static const String contact = 'Contact: $phoneNumber';
  static const String billCredit = '$developedBy | $contact';
  static const String craftedBy = 'Crafted with care by $name';
}
