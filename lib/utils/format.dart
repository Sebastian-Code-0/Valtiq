import 'numero_utils.dart';

String formatCOP(double monto) {
  final esNegativo = monto < 0;
  final signo = esNegativo ? '-\$' : '\$';
  final abs = monto.abs();

  // Magnitudes extremas se muestran en escala larga (es_CO) para que un
  // solo monto nunca produzca una cadena de 15+ dígitos que rompa layouts.
  if (abs >= 1e18) {
    return '$signo${_formatEscala(abs / 1e18)} trillones';
  }
  if (abs >= 1e12) {
    return '$signo${_formatEscala(abs / 1e12)} billones';
  }

  final digitos = abs.toStringAsFixed(0);
  final agrupado = agruparMiles(digitos);
  return '$signo$agrupado';
}

// El coeficiente ya dividido por 1e12/1e18 puede seguir siendo >= 1e21 si
// el monto original es lo bastante extremo, así que se acota antes de
// toStringAsFixed para nunca caer en notación exponencial. El '+' deja
// claro que el número mostrado es un piso, no la cifra exacta.
String _formatEscala(double coeficiente) {
  final excedido = coeficiente > maxCoeficiente;
  final valor = (excedido ? maxCoeficiente : coeficiente).toStringAsFixed(2);
  var texto = valor.replaceAll('.', ',');
  if (texto.endsWith(',00')) {
    texto = texto.substring(0, texto.length - 3);
  }
  return excedido ? '$texto+' : texto;
}

String formatTasaInicial(double t) {
  if (t == t.truncateToDouble()) return t.toStringAsFixed(0);
  return t.toStringAsFixed(2);
}
