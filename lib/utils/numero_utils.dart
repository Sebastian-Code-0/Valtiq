// Techo compartido para valores que se le pasan a toStringAsFixed: Dart cae
// a notación exponencial ("1e+21") en magnitudes >= 1e21, incluso después de
// dividir un monto extremo por 1e12 o 1e18. Este límite queda cómodamente
// por debajo de ese umbral.
const maxCoeficiente = 999999999999999.0;

String agruparMiles(String digitos) {
  final buffer = StringBuffer();
  for (var i = 0; i < digitos.length; i++) {
    if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digitos[i]);
  }
  return buffer.toString();
}
