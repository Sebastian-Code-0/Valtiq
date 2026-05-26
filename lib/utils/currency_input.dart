import 'package:flutter/services.dart';

double? parseCOP(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('\$')) s = s.substring(1).trim();
  s = s.replaceAll(' ', '');
  s = s.replaceAll('.', '');
  s = s.replaceAll(',', '.');
  return double.tryParse(s);
}

String formatCOPInput(double value) {
  final entero = value.abs().round();
  final str = entero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

class CopInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
