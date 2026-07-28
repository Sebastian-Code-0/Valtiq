import 'numero_utils.dart';

String formatCOP(double monto) {
  final esNegativo = monto < 0;
  final entero = monto.abs().round();
  final agrupado = agruparMiles(entero.toString());
  return '${esNegativo ? '-\$' : '\$'}$agrupado';
}

String formatTasaInicial(double t) {
  if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
  return t.toStringAsFixed(2);
}
