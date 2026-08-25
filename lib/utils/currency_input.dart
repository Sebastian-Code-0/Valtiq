import 'package:flutter/services.dart';

import 'numero_utils.dart';

// Techo propio del formateador de edición: a diferencia de formatCOP (que
// se acota a maxCoeficiente por espacio de layout), este debe preservar los
// dígitos exactos mientras Dart pueda representarlos en notación fija, y
// solo recurrir al clamp justo antes de que toStringAsFixed caiga a
// notación exponencial ("1e+21") en magnitudes >= 1e21.
//
// Un literal de 21 nueves (999999999999999999999.0) no sirve para esto:
// al no ser representable como double, se redondea exactamente a 1e21 (el
// propio umbral que se quiere evitar), y toStringAsFixed(0) de ese valor
// ya devuelve "1e+21". Este es el double más grande estrictamente menor
// a 1e21 (1e21 - 1 ULP), que sí formatea en notación fija.
const _maxValorEdicion = 999999999999999868928.0;

int? parseCOP(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (s.startsWith('\$')) s = s.substring(1).trim();
  s = s.replaceAll(' ', '');
  s = s.replaceAll('.', '');
  s = s.replaceAll(',', '.');
  final parsed = double.tryParse(s);
  return parsed?.round();
}

String formatCOPInput(num value) {
  final abs = value.abs();
  final acotado = abs > _maxValorEdicion ? _maxValorEdicion : abs;
  final digitos = acotado.toStringAsFixed(0);
  final agrupado = agruparMiles(digitos);
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
