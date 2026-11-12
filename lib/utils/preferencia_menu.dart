import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dónde va el menú en pantallas grandes: `false` = a la izquierda (lo de
/// siempre), `true` = arriba. En celular no aplica: ahí el menú va abajo.
/// Se elige en Ajustes → Apariencia y se guarda en este dispositivo.
final ValueNotifier<bool> menuSuperiorNotifier = ValueNotifier(false);

const _kMenuSuperior = 'valtiq_menu_superior';

Future<void> cargarMenuSuperior() async {
  final prefs = await SharedPreferences.getInstance();
  menuSuperiorNotifier.value = prefs.getBool(_kMenuSuperior) ?? false;
}

Future<void> setMenuSuperior(bool arriba) async {
  menuSuperiorNotifier.value = arriba;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kMenuSuperior, arriba);
}
