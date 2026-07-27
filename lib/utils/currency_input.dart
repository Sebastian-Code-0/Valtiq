import 'package:flutter/services.dart';

import 'numero_utils.dart';

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
  final agrupado = agruparMiles(entero.toString());
  return value < 0 ? '-$agrupado' : agrupado;
}

class CopInputFormatter extends TextInputFormatter {
  static final RegExp _noDigitos = RegExp(r'[^0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(_noDigitos, '');
    if (digits.isEmpty) {
      return const TextEditingValue();
    }
    final formatted = agruparMiles(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
