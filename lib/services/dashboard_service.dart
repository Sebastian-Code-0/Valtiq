import 'dart:async';

import 'package:drift/drift.dart' hide Column, Table;

import '../db/database.dart';
import 'interes_calculator.dart';

/// Agregaciones del dashboard, separadas de `DashboardScreen` para que sean
/// testeables sin levantar widgets. Cada método espeja exactamente lo que
/// antes vivía en `_DashboardScreenState.initState()` — mismo query, mismo
/// join sin agregar (necesario para `saldo_insoluto`, que necesita la fecha
/// de cada abono y no solo la suma, ver `InteresCalculator`).
/// Una deuda o un préstamo activo: a quién y cuánto falta hoy.
class SaldoActivo {
  const SaldoActivo(this.nombre, this.saldo);

  final String nombre;
  final int saldo;
}

class DashboardService {
  const DashboardService._();

  static Stream<double> watchTotalDeudasActivas(AppDatabase db) =>
      watchSaldosDeudasActivas(db).map(_sumar);

  static Stream<double> watchTotalPrestamosActivos(AppDatabase db) =>
      watchSaldosPrestamosActivos(db).map(_sumar);

  static double _sumar(List<SaldoActivo> lista) =>
      lista.fold<double>(0, (t, s) => t + s.saldo);

  /// Cada deuda activa con lo que falta pagarle hoy (con interés). La usan
  /// el total de Inicio y el widget de Android.
  static Stream<List<SaldoActivo>> watchSaldosDeudasActivas(AppDatabase db) {
    final d = db.deudas;
    final pd = db.pagosDeuda;
    final query = db.select(d).join([
      leftOuterJoin(pd, pd.deudaId.equalsExp(d.id)),
    ])..where(d.estado.equals('activa'));

    return query.watch().map((rows) {
      final deudas = <int, Deuda>{};
      final abonosPorDeuda = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final deuda = row.readTable(d);
        deudas[deuda.id] = deuda;
        final pago = row.readTableOrNull(pd);
        if (pago != null) {
          (abonosPorDeuda[deuda.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      return [
        for (final deuda in deudas.values)
          SaldoActivo(
            deuda.acreedorNombre,
            InteresCalculator.calcularDeudaTotal(
              montoPrestado: deuda.montoOriginal,
              tasaInteres: deuda.tasaInteres,
              tipoInteres: deuda.tipoInteres,
              modalidadCalculo: deuda.modalidadCalculo,
              fechaPrestamo: deuda.fechaPrestamo,
              totalAbonado: (abonosPorDeuda[deuda.id] ?? const []).fold<int>(
                0,
                (s, a) => s + a.monto,
              ),
              tipoAmortizacion: deuda.tipoAmortizacion,
              abonos: abonosPorDeuda[deuda.id] ?? const [],
            ),
          ),
      ];
    });
  }

  /// Cada préstamo activo con lo que falta cobrarle hoy (con interés).
  static Stream<List<SaldoActivo>> watchSaldosPrestamosActivos(AppDatabase db) {
    final p = db.prestamos;
    final pr = db.pagosRecibidos;
    final query = db.select(p).join([
      leftOuterJoin(pr, pr.prestamoId.equalsExp(p.id)),
    ])..where(p.estado.equals('activo'));

    return query.watch().map((rows) {
      final prestamos = <int, Prestamo>{};
      final abonosPorPrestamo = <int, List<AbonoInteres>>{};
      for (final row in rows) {
        final prestamo = row.readTable(p);
        prestamos[prestamo.id] = prestamo;
        final pago = row.readTableOrNull(pr);
        if (pago != null) {
          (abonosPorPrestamo[prestamo.id] ??= []).add(
            AbonoInteres(fecha: pago.fechaPago, monto: pago.montoAbonado),
          );
        }
      }
      return [
        for (final prestamo in prestamos.values)
          SaldoActivo(
            prestamo.deudorNombre,
            InteresCalculator.calcularDeudaTotal(
              montoPrestado: prestamo.montoPrestado,
              tasaInteres: prestamo.tasaInteres,
              tipoInteres: prestamo.tipoInteres,
              modalidadCalculo: prestamo.modalidadCalculo,
              fechaPrestamo: prestamo.fechaPrestamo,
              totalAbonado: (abonosPorPrestamo[prestamo.id] ?? const [])
                  .fold<int>(0, (s, a) => s + a.monto),
              tipoAmortizacion: prestamo.tipoAmortizacion,
              abonos: abonosPorPrestamo[prestamo.id] ?? const [],
            ),
          ),
      ];
    });
  }

  static Stream<double> watchIngresosMensuales(AppDatabase db) {
    final now = DateTime.now();
    return db.ingresosDao
        .watchTotalIngresosMes(now.year, now.month)
        .map((v) => v.toDouble());
  }

  static Stream<double> watchGastosFijosMensuales(AppDatabase db) {
    return db.gastosFijosDao.watchTotalMensualizado().map((v) => v.toDouble());
  }

  static Stream<double> watchGastosVariablesMes(AppDatabase db) {
    final now = DateTime.now();
    return db.gastosVariablesDao
        .watchTotalMes(now.year, now.month)
        .map((v) => v.toDouble());
  }

  /// Combina ingresos/gastos fijos/gastos variables del mes en un solo
  /// stream broadcast (combine-latest manual, sin depender de rxdart). Las
  /// suscripciones a las 3 fuentes se abren en `onListen` y se cierran en
  /// `onCancel`, así que el ciclo de vida sigue las reglas normales de un
  /// stream: nadie escuchando significa nada suscrito, igual que antes hacía
  /// `dispose()` en el widget.
  static Stream<({double ingresos, double gastos, double variables})>
  watchBalanceMensual(AppDatabase db) {
    final streamIngresos = watchIngresosMensuales(db);
    final streamGastos = watchGastosFijosMensuales(db);
    final streamVariables = watchGastosVariablesMes(db);

    late final StreamController<
      ({double ingresos, double gastos, double variables})
    >
    controller;
    StreamSubscription<double>? subIngresos, subGastos, subVariables;
    double ingresos = 0, gastos = 0, variables = 0;

    void emitir() {
      if (!controller.isClosed) {
        controller.add((
          ingresos: ingresos,
          gastos: gastos,
          variables: variables,
        ));
      }
    }

    controller = StreamController.broadcast(
      onListen: () {
        subIngresos = streamIngresos.listen((v) {
          ingresos = v;
          emitir();
        }, onError: (_) {});
        subGastos = streamGastos.listen((v) {
          gastos = v;
          emitir();
        }, onError: (_) {});
        subVariables = streamVariables.listen((v) {
          variables = v;
          emitir();
        }, onError: (_) {});
      },
      onCancel: () {
        subIngresos?.cancel();
        subGastos?.cancel();
        subVariables?.cancel();
      },
    );

    return controller.stream;
  }
}
