import 'package:intl/intl.dart';

/// Date and time formatting utilities for BillMate.
///
/// Provides consistent date display formats used on bills, history
/// entries, and the home screen. All formats are locale-aware through
/// the intl package.
abstract class BillDateUtils {
  BillDateUtils._();

  // ── Display formats ───────────────────────────────────────────

  /// Full display date for bill headers.
  ///
  /// Example: `"18 October 2026"`
  static String formatBillDate(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  /// Short date for list items and compact views.
  ///
  /// Example: `"18 Oct 2026"`
  static String formatShortDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Date and time for audit/timestamp display.
  ///
  /// Example: `"18 Oct 2026, 3:45 PM"`
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, h:mm a').format(date);
  }

  /// Relative label: "Today", "Yesterday", or the short date.
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return formatShortDate(date);
  }

  /// Returns the current date as a [DateTime] with time zeroed.
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Returns a formatted string for today's date using [formatBillDate].
  static String todayFormatted() => formatBillDate(today());
}
