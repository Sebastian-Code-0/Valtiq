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

/// Monto más grande que se puede escribir en Valtiq: 12 dígitos
/// (999.999.999.999, casi un billón de pesos).
///
/// Por qué hay tope: los montos se guardan como enteros de 64 bits, que
/// llegan hasta 9.223.372.036.854.775.807 (19 dígitos). Un número más largo
/// no cabe: antes se "aplastaba" a ese máximo al guardar y, al sumarlo con
/// otros, la suma se desbordaba y daba totales absurdos. Con 12 dígitos por
/// monto, ni las sumas ni los intereses se acercan a ese límite.
const int maxMonto = 999999999999;
const int maxDigitosMonto = 12;

/// [maxMonto] escrito para mostrarlo en un mensaje.
const String textoMaxMonto = r'$999.999.999.999';

/// Convierte lo escrito a pesos enteros. Es la ÚNICA lectura de un monto:
/// la usan el campo al teclear, al pegar y todo el que lee su valor.
/// Devuelve `null` si no se puede leer con certeza o si pasa de [maxMonto].
///
/// - Separadores repetidos son miles solo si la agrupación es válida: primer
///   grupo de 1 a 3 dígitos sin empezar en 0, los demás de 3 (`1,500,000`).
/// - Un último separador que no forma agrupación válida es decimal y lo que
///   sigue se ignora, sin redondear (`1500,50` = 1.500, `0,500` = 0). Con más
///   de 3 cifras no es un decimal creíble sino miles mal puestos (`1,500000`):
///   no se adivina.
int? parseCOP(String input) {
  var s = input.trim();
  if (s.startsWith(r'$')) s = s.substring(1).trim();
  var signo = 1;
  if (s.startsWith('-')) {
    signo = -1;
    s = s.substring(1);
  }
  final entero = _parteEntera(s);
  if (entero == null) return null;
  final limpio = entero.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  if (limpio.length > maxDigitosMonto) return null;
  return signo * int.parse(limpio);
}

final RegExp _soloDigitos = RegExp(r'^\d+$');
final RegExp _agrupado = RegExp(r'^[1-9]\d{0,2}(?:([., ])\d{3})(?:\1\d{3})*$');

/// Los dígitos enteros de [s], o `null` si no se lee con certeza.
String? _parteEntera(String s) {
  if (_soloDigitos.hasMatch(s)) return s;
  if (_agrupado.hasMatch(s)) return s.replaceAll(RegExp(r'[., ]'), '');
  final corte = s.lastIndexOf(RegExp(r'[.,]'));
  if (corte <= 0) return null;
  final decimales = s.substring(corte + 1);
  if (decimales.isNotEmpty && !_soloDigitos.hasMatch(decimales)) return null;
  if (decimales.length > 3) return null;
  final antes = s.substring(0, corte);
  if (_soloDigitos.hasMatch(antes)) return antes;
  // `1.500,50`: lo de antes es una agrupación con el OTRO separador.
  final m = _agrupado.firstMatch(antes);
  if (m == null || m[1] == s[corte]) {
    // `1,500,` termina en separador: lo de antes ya es el monto.
    return m != null && decimales.isEmpty
        ? antes.replaceAll(RegExp(r'[., ]'), '')
        : null;
  }
  return antes.replaceAll(RegExp(r'[., ]'), '');
}

String formatCOPInput(num value) {
  final abs = value.abs();
  final acotado = abs > _maxValorEdicion ? _maxValorEdicion : abs;
  final digitos = acotado.toStringAsFixed(0);
  final agrupado = agruparMiles(digitos);
  return value < 0 ? '-$agrupado' : agrupado;
}

/// Campo de monto en pesos: en COP no hay decimales. No guarda nada entre
/// una tecla y otra: todo sale del texto que se ve, que se lee con [parseCOP].
///
/// - Se escriben solo números: la coma y el punto del teclado no hacen nada
///   y los puntos de miles aparecen solos.
/// - Al pegar se entienden los formatos comunes (`$ 1.500.000,50`). Lo que no
///   se pueda leer con certeza o pase de [maxDigitosMonto] dígitos se rechaza:
///   el campo queda como estaba.
/// - Al borrar un dígito los ceros que quedan delante se conservan sin puntos
///   (`050000`), para poder escribir otro dígito sin perder el número.
class CopInputFormatter extends TextInputFormatter {
  static final RegExp _noDigitos = RegExp(r'[^0-9]');
  static final RegExp _invalidos = RegExp(r'[^0-9.,$\s]');

  static String _sinCeros(String digitos) =>
      digitos.replaceFirst(RegExp(r'^0+(?=\d)'), '');

  /// Qué cambió: `ini` caracteres iguales al inicio y `fin` al final.
  static (int, int) _cambio(TextEditingValue anterior, TextEditingValue nuevo) {
    final viejo = anterior.text;
    final texto = nuevo.text;
    // Lo seleccionado se reemplazó: es exacto aunque lo nuevo se parezca.
    final sel = anterior.selection;
    if (sel.isValid &&
        sel.end <= viejo.length &&
        texto.length >= viejo.length - (sel.end - sel.start) &&
        texto.startsWith(viejo.substring(0, sel.start)) &&
        texto.endsWith(viejo.substring(sel.end))) {
      return (sel.start, viejo.length - sel.end);
    }
    final tope = texto.length < viejo.length ? texto.length : viejo.length;
    final cursor = nuevo.selection.isValid
        ? nuevo.selection.end.clamp(0, texto.length)
        : texto.length;
    var fin = 0;
    while (fin < tope &&
        fin < texto.length - cursor &&
        viejo[viejo.length - 1 - fin] == texto[texto.length - 1 - fin]) {
      fin++;
    }
    var ini = 0;
    while (ini < tope - fin && viejo[ini] == texto[ini]) {
      ini++;
    }
    // Un cambio de varios caracteres sin selección conocida: todo el texto.
    if (texto.length - fin - ini > 1) return (0, 0);
    return (ini, fin);
  }

  static TextEditingValue _valor(String texto, int noPuntosAntes) {
    var vistos = 0;
    var offset = 0;
    while (offset < texto.length && vistos < noPuntosAntes) {
      if (texto.codeUnitAt(offset) != 0x2E) vistos++;
      offset++;
    }
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final viejo = oldValue.text;
    final nuevo = newValue.text;
    if (nuevo.isEmpty) return const TextEditingValue();
    final (ini, fin) = _cambio(oldValue, newValue);
    final quitado = viejo.substring(ini, viejo.length - fin);
    final puesto = nuevo.substring(ini, nuevo.length - fin);
    if (_invalidos.hasMatch(puesto)) return oldValue;

    // Pegar: se lee lo pegado, igual que todo lo demás.
    if (puesto.length > 1) {
      final monto = parseCOP(puesto);
      if (monto == null) return oldValue;
      final antes = viejo.substring(0, ini).replaceAll(_noDigitos, '');
      final despues = viejo
          .substring(viejo.length - fin)
          .replaceAll(_noDigitos, '');
      // Tal como se pegó si son solo dígitos: `05` en medio conserva su cero.
      final pegado = _soloDigitos.hasMatch(puesto) ? puesto : '$monto';
      return _digitos('$antes$pegado$despues', antes.length + pegado.length) ??
          oldValue;
    }

    // Coma y punto tecleados no hacen nada: los puntos de miles los pone el
    // campo. Si había algo seleccionado, solo se quita.
    if (puesto == ',' || puesto == '.') {
      return quitado.isEmpty ? oldValue : _sinSeleccion(oldValue, ini, fin);
    }

    var antes = viejo.substring(0, ini).replaceAll(_noDigitos, '');
    var despues = viejo
        .substring(viejo.length - fin)
        .replaceAll(_noDigitos, '');
    // Borrar un punto de miles borra el dígito de al lado: el de la
    // izquierda con Retroceso, el de la derecha con Supr.
    if (puesto.isEmpty && quitado == '.' && oldValue.selection.isCollapsed) {
      if (oldValue.selection.isValid && oldValue.selection.end == ini) {
        if (despues.isNotEmpty) despues = despues.substring(1);
      } else if (antes.isNotEmpty) {
        antes = antes.substring(0, antes.length - 1);
      }
    }
    final medio = puesto.replaceAll(_noDigitos, '');
    final escrito = '$antes$medio$despues';
    if (escrito.isEmpty) return const TextEditingValue();
    // Al borrar se conservan los ceros: `1.050.000` sin el 1 es `050000`, y
    // al escribir otro dígito delante vuelve a ser el mismo número.
    if (puesto.isEmpty && escrito.startsWith('0') && escrito.length > 1) {
      return TextEditingValue(
        text: escrito,
        selection: TextSelection.collapsed(offset: antes.length),
      );
    }
    return _digitos(escrito, antes.length + medio.length) ?? oldValue;
  }

  /// Quita lo seleccionado sin poner nada.
  TextEditingValue _sinSeleccion(TextEditingValue v, int ini, int fin) {
    final texto = v.text.replaceRange(ini, v.text.length - fin, '');
    return formatEditUpdate(
      v,
      TextEditingValue(
        text: texto,
        selection: TextSelection.collapsed(offset: ini),
      ),
    );
  }

  /// [escrito] (solo dígitos) ya agrupado, con el cursor después de
  /// [digitosAntes] de esos dígitos; `null` si pasa del tope.
  static TextEditingValue? _digitos(String escrito, int digitosAntes) {
    final digitos = _sinCeros(escrito);
    if (digitos.length > maxDigitosMonto) return null;
    final ceros = escrito.length - digitos.length;
    return _valor(
      agruparMiles(digitos),
      digitos == '0' ? 1 : (digitosAntes - ceros).clamp(0, digitos.length),
    );
  }
}
