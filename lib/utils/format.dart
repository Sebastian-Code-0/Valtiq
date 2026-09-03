import 'numero_utils.dart';

String formatCOP(num monto) {
  final esNegativo = monto < 0;
  final signo = esNegativo ? '-\$' : '\$';
  final abs = monto.abs();

  // Magnitudes extremas se muestran en escala larga (es_CO) para que un
  // solo monto nunca produzca una cadena de 15+ dígitos que rompa layouts.
  // Rangos intermedios (mil, diez mil, ..., mil millones, diez mil millones)
  // no tienen palabra propia en español y se quedan en dígitos agrupados
  // más abajo — solo billón (1e12) y trillón (1e18) sí la tienen.
  if (abs >= 1e18) {
    return '$signo${_formatEscala(abs / 1e18, singular: 'trillón', plural: 'trillones')}';
  }
  if (abs >= 1e12) {
    return '$signo${_formatEscala(abs / 1e12, singular: 'billón', plural: 'billones')}';
  }

  final digitos = abs.toStringAsFixed(0);
  final agrupado = agruparMiles(digitos);
  return '$signo$agrupado';
}

// El coeficiente ya dividido por 1e12/1e18 puede seguir siendo >= 1e21 si
// el monto original es lo bastante extremo, así que se acota antes de
// toStringAsFixed para nunca caer en notación exponencial. El '+' deja
// claro que el número mostrado es un piso, no la cifra exacta.
String _formatEscala(
  double coeficiente, {
  required String singular,
  required String plural,
}) {
  final excedido = coeficiente > maxCoeficiente;
  final valor = (excedido ? maxCoeficiente : coeficiente).toStringAsFixed(2);
  var texto = valor.replaceAll('.', ',');
  if (texto.endsWith(',00')) {
    texto = texto.substring(0, texto.length - 3);
  }
  // Solo el coeficiente exacto "1" (no "1,50" ni un valor topado por
  // maxCoeficiente) usa la forma singular — "1 billón", no "1 billones".
  final palabra = (!excedido && texto == '1') ? singular : plural;
  return excedido ? '$texto+ $plural' : '$texto $palabra';
}

String formatTasaInicial(double t) {
  if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
  return t.toStringAsFixed(2);
}
