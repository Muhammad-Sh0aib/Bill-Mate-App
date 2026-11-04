import 'package:intl/intl.dart';

import '../../../app/config/app_config.dart';

abstract class BillAmount {
  BillAmount._();

  // Keep accepted values exact on Dart VM and JavaScript targets.
  static const int _maxSupportedPaisa = 9007199254740991;
  static final RegExp _decimalPattern = RegExp(r'^\d+(?:\.\d{1,2})?$');
  static final NumberFormat _integerFormatter = NumberFormat(
    '#,##0',
    AppConfig.defaultLocale,
  );

  static int? parsePaisa(String input) {
    final value = input.trim();
    if (!_decimalPattern.hasMatch(value)) return null;

    final parts = value.split('.');
    final rupees = int.tryParse(parts.first);
    if (rupees == null) return null;

    final paisaText = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    final paisa = int.parse(paisaText);
    if (rupees > (_maxSupportedPaisa - paisa) ~/ 100) return null;

    return rupees * 100 + paisa;
  }

  static String formatPaisa(int paisa) {
    if (paisa < 0) {
      throw ArgumentError.value(paisa, 'paisa', 'Must not be negative.');
    }
    return formatPaisaBigInt(BigInt.from(paisa));
  }

  static String formatPaisaBigInt(BigInt paisa) {
    if (paisa < BigInt.zero) {
      throw ArgumentError.value(paisa, 'paisa', 'Must not be negative.');
    }
    final rupees = paisa ~/ BigInt.from(100);
    final remainder = (paisa % BigInt.from(100)).toString().padLeft(2, '0');
    final formattedRupees = rupees <= BigInt.from(_maxSupportedPaisa)
        ? _integerFormatter.format(rupees.toInt())
        : _groupDigits(rupees.toString());
    return '${AppConfig.currencySymbol} $formattedRupees.$remainder';
  }

  static String _groupDigits(String digits) {
    final result = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        result.write(',');
      }
      result.write(digits[index]);
    }
    return result.toString();
  }
}
