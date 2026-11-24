import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'numero_utils.dart';

/// "Ocultar montos": cuando está activo, las pantallas que usan
/// [formatMonto] muestran puntos en vez de cifras (para abrir la app delante
/// de otras personas). Se guarda entre sesiones.
final ValueNotifier<bool> montosOcultosNotifier = ValueNotifier(false);

const _kMontosOcultos = 'valtiq_ocultar_montos';

/// Texto que reemplaza a cualquier monto oculto.
const montoOculto = r'$ ••••••';

Future<void> cargarMontosOcultos() async {
  final prefs = await SharedPreferences.getInstance();
  montosOcultosNotifier.value = prefs.getBool(_kMontosOcultos) ?? false;
}

Future<void> setMontosOcultos(bool ocultos) async {
  montosOcultosNotifier.value = ocultos;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kMontosOcultos, ocultos);
}

/// Igual que [formatCOP], pero respeta "Ocultar montos". Usar en lo que se
/// MUESTRA en pantalla; [formatCOP] queda para lo que no debe ocultarse
/// nunca (correos, notificaciones, mensajes de validación).
String formatMonto(num monto) =>
    montosOcultosNotifier.value ? montoOculto : formatCOP(monto);

String formatCOP(num monto) {
  if (monto.isNaN) return r'$0';
  final abs = monto.abs();
  // Un valor que redondea a cero no lleva signo ("-$0").
  final esNegativo = monto < 0 && abs >= 0.5;
  final signo = esNegativo ? '-\$' : '\$';

  // Magnitudes extremas se muestran en escala larga (es_CO) para que un
  // solo monto nunca produzca una cadena de 15+ dígitos que rompa layouts.
  // Rangos intermedios (mil, diez mil, ..., mil millones, diez mil millones)
  // no tienen palabra propia en español y se quedan en dígitos agrupados
  // más abajo — solo billón (1e12) y trillón (1e18) sí la tienen.
  if (abs >= 1e18) {
    return '$signo${_formatEscala(abs / 1e18, singular: 'trillón', plural: 'trillones')}';
  }
  // 999.999.999.999,6 redondea a un billón: no debe salir con 13 dígitos.
  if (abs >= 1e12 - 0.5) {
    return '$signo${_formatEscala((abs < 1e12 ? 1e12 : abs) / 1e12, singular: 'billón', plural: 'billones')}';
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
  // Se trunca a dos decimales: redondear haría que 999,999… billones se
  // leyera como "1000 billones", más de lo que es.
  final truncado = excedido
      ? maxCoeficiente
      : ((coeficiente * 100 + 1e-11).floorToDouble() / 100);
  final valor = truncado.toStringAsFixed(2);
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
