import 'package:drift/drift.dart';

import '../../utils/categoria_gasto.dart';
import '../database.dart';
import '../tables.dart';

part 'categorias_dao.g.dart';

/// Lo que tiene asociado una categoría: se muestra antes de borrarla.
class UsoCategoria {
  const UsoCategoria({
    required this.gastos,
    required this.totalGastos,
    this.limiteMensual,
  });

  /// Cuántos gastos del día a día la usan (de todos los meses).
  final int gastos;
  final int totalGastos;

  /// Su presupuesto mensual, si tiene.
  final int? limiteMensual;

  bool get vacia => gastos == 0 && limiteMensual == null;
}

/// Lo que pasó al borrar una categoría: se muestra después, en la misma
/// ventana.
class CategoriaBorrada {
  const CategoriaBorrada({
    required this.nombre,
    required this.uso,
    required this.gastosMovidos,
  });

  final String nombre;
  final UsoCategoria uso;

  /// true = los gastos pasaron a "Otros"; false = se borraron.
  final bool gastosMovidos;
}

@DriftAccessor(tables: [Categorias, GastosVariables, PresupuestosCategorias])
class CategoriasDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriasDaoMixin {
  CategoriasDao(super.db);

  /// Nombre de la categoría que no se puede borrar ni renombrar: es a donde
  /// van los gastos de una categoría borrada.
  static final nombreOtros = CategoriaGasto.otros.nombre;

  SimpleSelectStatement<$CategoriasTable, Categoria> _ordenadas() => select(
    categorias,
  )..orderBy([(c) => OrderingTerm.asc(c.orden), (c) => OrderingTerm.asc(c.id)]);

  Stream<List<Categoria>> watchCategorias() => _ordenadas().watch();

  Future<List<Categoria>> getCategorias() => _ordenadas().get();

  /// Si ya hay una categoría con ese nombre (sin importar mayúsculas ni
  /// espacios). [salvoId] excluye la que se está editando.
  Future<bool> existeNombre(String nombre, {int? salvoId}) async {
    final buscado = nombre.trim().toLowerCase();
    for (final c in await getCategorias()) {
      if (c.id != salvoId && c.nombre.trim().toLowerCase() == buscado) {
        return true;
      }
    }
    return false;
  }

  /// Crea una categoría al final de la lista.
  Future<int> crear({
    required String nombre,
    required String icono,
    required int color,
  }) async {
    final max = categorias.orden.max();
    final fila = await (selectOnly(categorias)..addColumns([max])).getSingle();
    return into(categorias).insert(
      CategoriasCompanion.insert(
        nombre: nombre.trim(),
        icono: Value(icono),
        color: color,
        orden: Value((fila.read(max) ?? -1) + 1),
      ),
    );
  }

  /// Cambia nombre, ícono y color. Si cambia el nombre, también lo cambia en
  /// los gastos y en el presupuesto que la usan (todo o nada).
  Future<void> actualizar(
    Categoria actual, {
    required String nombre,
    required String icono,
    required int color,
  }) {
    final nuevo = actual.nombre == nombreOtros ? nombreOtros : nombre.trim();
    return transaction(() async {
      await (update(categorias)..where((c) => c.id.equals(actual.id))).write(
        CategoriasCompanion(
          nombre: Value(nuevo),
          icono: Value(icono),
          color: Value(color),
        ),
      );
      if (nuevo != actual.nombre) {
        await (update(gastosVariables)
              ..where((g) => g.categoria.equals(actual.nombre)))
            .write(GastosVariablesCompanion(categoria: Value(nuevo)));
        await (update(presupuestosCategorias)
              ..where((p) => p.categoria.equals(actual.nombre)))
            .write(PresupuestosCategoriasCompanion(categoria: Value(nuevo)));
      }
    });
  }

  /// Guarda un orden nuevo: la posición en [ids] es el orden.
  Future<void> reordenar(List<int> ids) => transaction(() async {
    for (final (i, id) in ids.indexed) {
      await (update(categorias)..where((c) => c.id.equals(id))).write(
        CategoriasCompanion(orden: Value(i)),
      );
    }
  });

  Future<UsoCategoria> usoDe(String nombre) async {
    final cuenta = gastosVariables.id.count();
    final suma = gastosVariables.monto.sum();
    final fila =
        await (selectOnly(gastosVariables)
              ..addColumns([cuenta, suma])
              ..where(gastosVariables.categoria.equals(nombre)))
            .getSingle();
    final presupuesto = await (select(
      presupuestosCategorias,
    )..where((p) => p.categoria.equals(nombre))).getSingleOrNull();
    return UsoCategoria(
      gastos: fila.read(cuenta) ?? 0,
      totalGastos: fila.read(suma) ?? 0,
      limiteMensual: presupuesto?.limiteMensual,
    );
  }

  /// Borra la categoría y su presupuesto. Sus gastos del día a día se
  /// borran o, con [moverAOtros], pasan a "Otros". Todo o nada.
  ///
  /// "Otros" no se puede borrar: lanza [StateError].
  Future<CategoriaBorrada> borrar(
    Categoria categoria, {
    required bool moverAOtros,
  }) {
    if (categoria.nombre == nombreOtros) {
      throw StateError('La categoría "$nombreOtros" no se puede borrar.');
    }
    return transaction(() async {
      final uso = await usoDe(categoria.nombre);
      final suyos = gastosVariables.categoria.equals(categoria.nombre);
      if (moverAOtros) {
        await (update(gastosVariables)..where((_) => suyos)).write(
          GastosVariablesCompanion(categoria: Value(nombreOtros)),
        );
      } else {
        await (delete(gastosVariables)..where((_) => suyos)).go();
      }
      await (delete(
        presupuestosCategorias,
      )..where((p) => p.categoria.equals(categoria.nombre))).go();
      await (delete(categorias)..where((c) => c.id.equals(categoria.id))).go();
      return CategoriaBorrada(
        nombre: categoria.nombre,
        uso: uso,
        gastosMovidos: moverAOtros && uso.gastos > 0,
      );
    });
  }
}
