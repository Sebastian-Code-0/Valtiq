import 'package:drift/drift.dart';

import '../../utils/frecuencia.dart';
import '../database.dart';
import '../tables.dart';

part 'ingresos_dao.g.dart';

@DriftAccessor(tables: [Ingresos])
class IngresosDao extends DatabaseAccessor<AppDatabase>
    with _$IngresosDaoMixin {
  IngresosDao(super.db);

  Future<List<Ingreso>> getAllIngresos() {
    return (select(
      ingresos,
    )..orderBy([(t) => OrderingTerm.desc(t.fecha)])).get();
  }

  Future<List<Ingreso>> getIngresosActivos() {
    return (select(ingresos)..where((t) => t.activo.equals(true))).get();
  }

  Future<Ingreso?> getIngresoById(int id) {
    return (select(ingresos)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertIngreso(IngresosCompanion ingreso) {
    return into(ingresos).insert(ingreso);
  }

  Future<bool> updateIngreso(Ingreso ingreso) {
    return update(ingresos).replace(ingreso);
  }

  Future<int> deleteIngreso(int id) {
    return (delete(ingresos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setActivo(int id, {required bool activo}) async {
    await (update(ingresos)..where((t) => t.id.equals(id))).write(
      IngresosCompanion(
        activo: Value(activo),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }

  Future<int> getTotalIngresosActivos() async {
    final sum = ingresos.monto.sum();
    final query = selectOnly(ingresos)
      ..addColumns([sum])
      ..where(ingresos.activo.equals(true));
    final row = await query.getSingle();
    return row.read(sum) ?? 0;
  }

  /// Total de ingresos que cuentan para `anio`/`mes`: las fuentes recurrentes
  /// (`frecuencia` distinta de 'unico') se cuentan siempre, sin importar su
  /// `fecha` — representan un ingreso continuo (salario, renta), igual que
  /// `GastosFijos` — pero el `monto` guardado es POR PERÍODO, así que se
  /// multiplica por `factorMensual` (quincenal ×2, semanal ×52/12) antes de
  /// sumar, para no reportar de menos a quien cobra distinto a mensual. Un
  /// ingreso 'unico' (pago puntual, ej. un trabajo secundario) no se
  /// prorratea — solo cuenta, tal cual, en el mes de su propia `fecha` —
  /// igual que `GastosVariables.watchTotalMes` — para no seguir sumándolo
  /// para siempre una vez pasado ese mes.
  ///
  /// Agregación hecha en Dart (no SQL `sum()`) porque el multiplicador
  /// depende de `frecuencia` fila por fila — mismo patrón ya usado en
  /// `dashboard_screen.dart` para deudas/préstamos con `saldo_insoluto`. El
  /// volumen de filas en esta tabla es siempre chico (fuentes de ingreso de
  /// una persona), así que no hay costo real de traer todo a Dart.
  Stream<int> watchTotalIngresosMes(int anio, int mes) {
    final inicio = DateTime.utc(anio, mes, 1);
    final fin = DateTime.utc(anio, mes + 1, 1);
    return (select(ingresos)..where((t) => t.activo.equals(true))).watch().map((
      lista,
    ) {
      var total = 0;
      for (final i in lista) {
        if (i.frecuencia == 'unico') {
          if (!i.fecha.isBefore(inicio) && i.fecha.isBefore(fin)) {
            total += i.monto;
          }
          continue;
        }
        total += (i.monto * factorMensual(i.frecuencia)).round();
      }
      return total;
    });
  }

  /// Ingresos 'unico' activos cuyo mes/año de `fecha` ya quedó en el pasado
  /// respecto a `inicioMesActual` (medianoche UTC del día 1 del mes de hoy)
  /// — candidatos a desactivar automáticamente al abrir la app en un mes
  /// nuevo. No incluye ni el mes actual ni uno futuro.
  Future<List<Ingreso>> getUnicosVencidos(DateTime inicioMesActual) {
    return (select(ingresos)..where(
          (t) =>
              t.activo.equals(true) &
              t.frecuencia.equals('unico') &
              t.fecha.isSmallerThanValue(inicioMesActual),
        ))
        .get();
  }

  Future<void> desactivarVarios(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(ingresos)..where((t) => t.id.isIn(ids))).write(
      IngresosCompanion(
        activo: Value(false),
        actualizadoEn: Value(DateTime.now()),
      ),
    );
  }
}
