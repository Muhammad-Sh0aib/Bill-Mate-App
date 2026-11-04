import 'package:intl/intl.dart';

import '../../app/config/app_config.dart';

/// Currency formatting utilities for BillMate.
///
/// All monetary amounts in the app are in PKR. Use this class rather
/// than constructing [NumberFormat] instances ad hoc to ensure
/// consistent formatting across all screens and document previews.
abstract class CurrencyUtils {
  CurrencyUtils._();

  // ── Formatters ────────────────────────────────────────────────

  /// Formats an amount with the PKR currency symbol and two decimal places.
  ///
  /// Example: `formatAmount(1500.0)` → `"Rs. 1,500.00"`
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: AppConfig.defaultLocale,
      symbol: '${AppConfig.currencySymbol} ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Formats an amount without decimal places for compact display.
  ///
  /// Example: `formatAmountCompact(1500.0)` → `"Rs. 1,500"`
  static String formatAmountCompact(double amount) {
    final formatter = NumberFormat.currency(
      locale: AppConfig.defaultLocale,
      symbol: '${AppConfig.currencySymbol} ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Formats a raw number with thousands separators, no symbol.
  ///
  /// Example: `formatNumber(1500000.0)` → `"1,500,000"`
  static String formatNumber(double value) {
    return NumberFormat('#,##0.##', AppConfig.defaultLocale).format(value);
  }

  /// Attempts to parse a user-entered string as a monetary amount.
  ///
  /// Returns `null` if the string is not a valid number.
  /// Removes common formatting characters before parsing.
  static double? parseAmount(String raw) {
    final cleaned = raw
        .replaceAll(AppConfig.currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned);
  }

  /// Returns `true` if [amount] is a valid, non-negative monetary value.
  static bool isValidAmount(double? amount) {
    return amount != null && amount >= 0 && amount.isFinite;
  }
}
