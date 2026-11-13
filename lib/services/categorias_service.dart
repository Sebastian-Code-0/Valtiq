import 'dart:async';

import 'package:flutter/material.dart';

import '../db/database.dart';
import '../utils/categoria_gasto.dart';
import '../utils/iconos_categoria.dart';

/// Las categorías de gasto (editables desde schemaVersion 15) siempre a
/// mano en memoria, para que las listas puedan pintar el ícono y el color de
/// cada gasto sin esperar a la base. Se carga en `main()` antes de `runApp`
/// y se mantiene al día sola.
///
/// Si todavía no se cargó (en las pruebas, por ejemplo) responde con las
/// categorías de fábrica de [CategoriaGasto].
abstract final class CategoriasService {
  static final lista = ValueNotifier<List<Categoria>>(const []);
  static StreamSubscription<List<Categoria>>? _suscripcion;

  static Future<void> iniciar(AppDatabase db) async {
    lista.value = await db.categoriasDao.getCategorias();
    await _suscripcion?.cancel();
    _suscripcion = db.categoriasDao.watchCategorias().listen(
      (v) => lista.value = v,
    );
  }

  static Categoria? buscar(String nombre) {
    for (final c in lista.value) {
      if (c.nombre == nombre) return c;
    }
    return null;
  }

  /// Nombres en el orden en que se muestran.
  static List<String> get nombres => lista.value.isEmpty
      ? CategoriaGasto.nombres
      : [for (final c in lista.value) c.nombre];

  static IconData iconoPara(String nombre) {
    final c = buscar(nombre);
    return c == null ? CategoriaGasto.iconoPara(nombre) : iconoDeClave(c.icono);
  }

  static Color colorPara(String nombre) {
    final c = buscar(nombre);
    return c == null ? CategoriaGasto.colorPara(nombre) : Color(c.color);
  }
}
