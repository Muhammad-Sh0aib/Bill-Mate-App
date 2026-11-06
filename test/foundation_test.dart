// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bill_mate/app/config/app_config.dart';
import 'package:bill_mate/core/constants/app_constants.dart';
import 'package:bill_mate/core/utils/currency_utils.dart';
import 'package:bill_mate/core/utils/date_utils.dart';
import 'package:bill_mate/core/errors/app_exception.dart';
import 'package:bill_mate/core/errors/error_handler.dart';

void main() {
  setUp(() {
    databaseFactory = databaseFactoryFfi;
  });

  group('AppConfig', () {
    test('has correct app name', () {
      expect(AppConfig.appName, equals('BillMate'));
    });

    test('has correct default company name (exact spelling required)', () {
      // The client supplied "Babar Machnical Work" — do not correct spelling.
      expect(AppConfig.defaultCompanyName, equals('Babar Machnical Work'));
    });

    test('has correct default company phone', () {
      expect(AppConfig.defaultCompanyPhone, equals('0300-2246183'));
    });

    test('has PKR currency code', () {
      expect(AppConfig.currencyCode, equals('PKR'));
    });

    test('has Rs. currency symbol', () {
      expect(AppConfig.currencySymbol, equals('Rs.'));
    });

    test('has en_PK default locale', () {
      expect(AppConfig.defaultLocale, equals('en_PK'));
    });
  });

  group('AppConstants', () {
    test('database name is set', () {
      expect(AppConstants.databaseName, equals('bill_mate.db'));
    });

    test('database version includes the saved-bill migration', () {
      expect(AppConstants.databaseVersion, equals(3));
    });

    test('maxBillHistory is 7 as per roadmap', () {
      expect(AppConstants.maxBillHistory, equals(7));
    });

    test('maxBillItems is a reasonable positive value', () {
      expect(AppConstants.maxBillItems, greaterThan(0));
    });

    test('animation durations are positive', () {
      expect(AppConstants.animationFast.inMilliseconds, greaterThan(0));
      expect(AppConstants.animationNormal.inMilliseconds, greaterThan(0));
      expect(AppConstants.animationSlow.inMilliseconds, greaterThan(0));
    });
  });

  group('CurrencyUtils', () {
    test('formatAmount formats with Rs. symbol and two decimal places', () {
      final result = CurrencyUtils.formatAmount(1500.0);
      expect(result, contains('Rs.'));
      expect(result, contains('1,500'));
    });

    test('formatAmount handles zero', () {
      final result = CurrencyUtils.formatAmount(0.0);
      expect(result, contains('Rs.'));
      expect(result, contains('0'));
    });

    test('formatAmount handles large amounts', () {
      final result = CurrencyUtils.formatAmount(1000000.0);
      expect(result, contains('1,000,000'));
    });

    test('formatAmountCompact omits decimal places', () {
      final result = CurrencyUtils.formatAmountCompact(2500.5);
      expect(result, contains('Rs.'));
      expect(result, isNot(contains('.50')));
    });

    test('parseAmount parses plain number string', () {
      expect(CurrencyUtils.parseAmount('1500'), equals(1500.0));
    });

    test('parseAmount parses number with commas', () {
      expect(CurrencyUtils.parseAmount('1,500'), equals(1500.0));
    });

    test('parseAmount parses number with Rs. symbol', () {
      expect(CurrencyUtils.parseAmount('Rs. 1500'), closeTo(1500.0, 0.001));
    });

    test('parseAmount returns null for invalid input', () {
      expect(CurrencyUtils.parseAmount('abc'), isNull);
      expect(CurrencyUtils.parseAmount(''), isNull);
    });

    test('isValidAmount returns true for non-negative finite values', () {
      expect(CurrencyUtils.isValidAmount(0.0), isTrue);
      expect(CurrencyUtils.isValidAmount(100.0), isTrue);
    });

    test('isValidAmount returns false for null or negative', () {
      expect(CurrencyUtils.isValidAmount(null), isFalse);
      expect(CurrencyUtils.isValidAmount(-1.0), isFalse);
    });

    test('isValidAmount returns false for infinity', () {
      expect(CurrencyUtils.isValidAmount(double.infinity), isFalse);
    });
  });

  group('BillDateUtils', () {
    final testDate = DateTime(2026, 10, 18);

    test('formatBillDate returns full date string', () {
      final result = BillDateUtils.formatBillDate(testDate);
      expect(result, equals('18 October 2026'));
    });

    test('formatShortDate returns abbreviated date string', () {
      final result = BillDateUtils.formatShortDate(testDate);
      expect(result, equals('18 Oct 2026'));
    });

    test('formatDateTime includes time component', () {
      final dateWithTime = DateTime(2026, 10, 18, 15, 30);
      final result = BillDateUtils.formatDateTime(dateWithTime);
      expect(result, contains('18 Oct 2026'));
      expect(result, contains('3:30'));
    });

    test('formatRelativeDate returns Today for today', () {
      final result = BillDateUtils.formatRelativeDate(DateTime.now());
      expect(result, equals('Today'));
    });

    test('formatRelativeDate returns Yesterday for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = BillDateUtils.formatRelativeDate(yesterday);
      expect(result, equals('Yesterday'));
    });

    test('formatRelativeDate returns short date for older dates', () {
      final old = DateTime(2025, 1, 1);
      final result = BillDateUtils.formatRelativeDate(old);
      expect(result, equals('01 Jan 2025'));
    });

    test('today() returns midnight of current day', () {
      final t = BillDateUtils.today();
      expect(t.hour, equals(0));
      expect(t.minute, equals(0));
      expect(t.second, equals(0));
    });
  });

  group('AppException', () {
    test('StorageException preserves message', () {
      const ex = StorageException('DB write failed');
      expect(ex.message, equals('DB write failed'));
    });

    test('ValidationException preserves message', () {
      const ex = ValidationException('Invalid amount');
      expect(ex.message, equals('Invalid amount'));
    });

    test('NotFoundException preserves message', () {
      const ex = NotFoundException('Bill not found');
      expect(ex.message, equals('Bill not found'));
    });

    test('toString includes runtimeType and message', () {
      const ex = StorageException('error text');
      expect(ex.toString(), contains('StorageException'));
      expect(ex.toString(), contains('error text'));
    });
  });

  group('ErrorHandler', () {
    test('userMessage returns friendly message for StorageException', () {
      const ex = StorageException('internal db error');
      final msg = ErrorHandler.userMessage(ex);
      expect(msg, isNot(contains('internal db error')));
      expect(msg, isNotEmpty);
    });

    test('userMessage returns the message for ValidationException', () {
      const ex = ValidationException('Amount must be positive');
      final msg = ErrorHandler.userMessage(ex);
      expect(msg, equals('Amount must be positive'));
    });

    test('userMessage returns generic fallback for unknown errors', () {
      final msg = ErrorHandler.userMessage(Exception('something weird'));
      expect(msg, equals('Something went wrong. Please try again.'));
    });
  });
}
