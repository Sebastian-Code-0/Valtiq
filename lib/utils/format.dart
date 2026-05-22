String formatCOP(double monto) {
  final esNegativo = monto < 0;
  final entero = monto.abs().round();
  final str = entero.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
    buffer.write(str[i]);
  }
  return '${esNegativo ? '-\$' : '\$'}$buffer';
}
