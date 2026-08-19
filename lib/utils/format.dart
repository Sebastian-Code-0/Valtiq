import 'numero_utils.dart';

String formatCOP(double monto) {
  final esNegativo = monto < 0;
  final signo = esNegativo ? '-\$' : '\$';
  final abs = monto.abs();

  // Magnitudes extremas se muestran en escala larga (es_CO) para que un
  // solo monto nunca produzca una cadena de 15+ dígitos que rompa layouts.
  if (abs >= 1e18) {
    final valor = (abs / 1e18).toStringAsFixed(2).replaceAll('.', ',');
    return '$signo$valor trillones';
  }
  if (abs >= 1e12) {
    final valor = (abs / 1e12).toStringAsFixed(2).replaceAll('.', ',');
    return '$signo$valor billones';
  }

  final digitos = abs.toStringAsFixed(0);
  final agrupado = agruparMiles(digitos);
  return '$signo$agrupado';
}

String formatTasaInicial(double t) {
  if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
  return t.toStringAsFixed(2);
}
