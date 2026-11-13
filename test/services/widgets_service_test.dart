import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/dashboard_service.dart';
import 'package:valtiq/services/widgets_service.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/format.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);

  test('widget de deudas: el total de hoy y de los días que siguen (el '
      'interés sube cada día), desde hoy', () {
    final dia0 = normalizarFechaCivil(hoy);
    final datos = contenidoWidgetResumen(TipoWidgetResumen.deudas, [
      CuentaActiva('Nu', (d) => 100000 + 1000 * d!.difference(dia0).inDays),
      CuentaActiva('Mamá', (_) => 50000),
    ], hoy);
    expect(datos['deudas_desde'], '2026-11-12');
    final totales = datos['deudas_totales']!.split('\n');
    expect(totales, hasLength(diasWidgetResumen));
    expect(totales[0], r'$150.000');
    expect(totales[1], r'$151.000');
    expect(totales[30], r'$180.000');
    expect(datos['deudas_nota'], 'Lo que debes hoy');
  });

  test('widget de préstamos vacío: \$0 y "Nadie te debe por ahora"', () {
    final vacio = contenidoWidgetResumen(
      TipoWidgetResumen.prestamos,
      const [],
      hoy,
    );
    expect(vacio['prestamos_totales']!.split('\n').first, r'$0');
    expect(vacio['prestamos_nota'], 'Nadie te debe por ahora');
  });

  test('con una deuda real con interés, el total de dentro de 30 días es el '
      'que dará Valtiq ese día', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final inicio = DateTime.utc(2026, 10, 1);
    await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Banco',
        montoOriginal: 1000000,
        fechaPrestamo: inicio,
        tasaInteres: const Value(2),
        tipoInteres: const Value('mensual'),
      ),
    );
    final cuentas = await DashboardService.watchDeudasActivas(db).first;
    final datos = contenidoWidgetResumen(
      TipoWidgetResumen.deudas,
      cuentas,
      hoy,
    );
    final totales = datos['deudas_totales']!.split('\n');
    final en30 = InteresCalculator.calcularDeudaTotal(
      montoPrestado: 1000000,
      tasaInteres: 2,
      tipoInteres: 'mensual',
      modalidadCalculo:
          (await db.deudasDao.getAllDeudas()).single.modalidadCalculo,
      fechaPrestamo: inicio,
      totalAbonado: 0,
      fechaFin: DateTime.utc(2026, 12, 12),
    );
    expect(totales[30], formatCOP(en30));
    expect(totales[30], isNot(totales[0]), reason: 'el interés sí cambia');
  });

  test('seccionDeUri: solo las secciones de los widgets', () {
    expect(WidgetsService.seccionDeUri(Uri.parse('valtiq://deudas')), 'deudas');
    expect(
      WidgetsService.seccionDeUri(Uri.parse('valtiq://prestamos')),
      'prestamos',
    );
    expect(WidgetsService.seccionDeUri(Uri.parse('valtiq://ajustes')), isNull);
    expect(WidgetsService.seccionDeUri(Uri.parse('https://deudas')), isNull);
    expect(WidgetsService.seccionDeUri(null), isNull);
  });

  test('saldos por deuda y préstamo activos (lo que leen los widgets); los '
      'pagados no cuentan', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fecha = normalizarFechaCivil(DateTime.now());
    final nu = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Nu',
        montoOriginal: 500000,
        fechaPrestamo: fecha,
      ),
    );
    await db.pagosDeudaDao.insertPago(
      PagosDeudaCompanion.insert(
        deudaId: nu,
        montoAbonado: 100000,
        fechaPago: fecha,
      ),
    );
    await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Vieja',
        montoOriginal: 9000,
        fechaPrestamo: fecha,
        estado: const Value('pagada'),
      ),
    );
    await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Ana',
        montoPrestado: 70000,
        fechaPrestamo: fecha,
      ),
    );

    final deudas = await DashboardService.watchSaldosDeudasActivas(db).first;
    expect(deudas.map((s) => (s.nombre, s.saldo)), [('Nu', 400000)]);
    final prestamos = await DashboardService.watchSaldosPrestamosActivos(
      db,
    ).first;
    expect(prestamos.map((s) => (s.nombre, s.saldo)), [('Ana', 70000)]);
    expect(await DashboardService.watchTotalDeudasActivas(db).first, 400000);
  });
}
