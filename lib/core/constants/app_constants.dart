/// Shared application constants that do not belong to a specific feature.
///
/// Feature-specific constants should live in their own feature's
/// constants file. Do not add business logic or state here.
abstract class AppConstants {
  AppConstants._();

  // ── Database ──────────────────────────────────────────────────
  /// SQLite database file name (created in Phase 7).
  static const String databaseName = 'bill_mate.db';

  /// Current database schema version.
  static const int databaseVersion = 2;

  // ── Bill limits ───────────────────────────────────────────────
  /// Maximum number of line items per bill.
  /// Enforced in the bill editor (Phase 4).
  static const int maxBillItems = 50;

  /// Maximum number of bills retained in the history.
  /// The retention policy will be configurable in Phase 8.
  static const int maxBillHistory = 7;

  // ── Formatting ────────────────────────────────────────────────
  /// Number of decimal places used for monetary amounts on bills.
  static const int amountDecimalPlaces = 2;

  // ── UI durations ──────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 400);
  static const Duration snackBarDuration = Duration(seconds: 3);
}
