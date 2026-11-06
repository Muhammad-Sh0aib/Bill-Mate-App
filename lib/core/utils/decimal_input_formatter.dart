import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  DecimalInputFormatter({this.decimalPlaces = 2})
    : _pattern = RegExp('^\\d*(?:\\.\\d{0,$decimalPlaces})?\$');

  final int decimalPlaces;
  final RegExp _pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _pattern.hasMatch(newValue.text) ? newValue : oldValue;
  }
}
