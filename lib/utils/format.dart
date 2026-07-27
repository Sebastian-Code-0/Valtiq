import 'numero_utils.dart';

String formatCOP(double monto) {
  final esNegativo = monto < 0;
  final entero = monto.abs().round();
  final agrupado = agruparMiles(entero.toString());
  return '${esNegativo ? '-\$' : '\$'}$agrupado';
}
