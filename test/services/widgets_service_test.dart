import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/dashboard_service.dart';
import 'package:valtiq/services/widgets_service.dart';
import 'package:valtiq/utils/fecha_civil.dart';

void main() {
  final hoy = DateTime(2026, 11, 12);

  test('widget de deudas: total, cuántas, las 3 mayores y "+ N más"', () {
    final datos = contenidoWidgetResumen(TipoWidgetResumen.deudas, const [
      SaldoActivo('Juan', 50000),
      SaldoActivo('Nu', 1200000),
      SaldoActivo('Addi', 300000),
      SaldoActivo('Mamá', 80000),
    ], hoy);
    expect(datos['deudas_total'], r'$1.630.000');
    expect(datos['deudas_cantidad'], '4 deudas activas');
    expect(
      [for (var i = 0; i < 3; i++) datos['deudas_nombre_$i']],
      ['Nu', 'Addi', 'Mamá'],
    );
    expect(datos['deudas_monto_0'], r'$1.200.000');
    expect(datos['deudas_mas'], '+ 1 más');
    expect(datos['deudas_actualizado'], 'Actualizado 12 nov');
  });

  test('widget de préstamos: singular, y vacío sin filas', () {
    final uno = contenidoWidgetResumen(TipoWidgetResumen.prestamos, const [
      SaldoActivo('Ana', 20000),
    ], hoy);
    expect(uno['prestamos_cantidad'], '1 persona te debe');
    expect(uno['prestamos_nombre_1'], '');
    expect(uno['prestamos_mas'], '');

    final vacio = contenidoWidgetResumen(
      TipoWidgetResumen.prestamos,
      const [],
      hoy,
    );
    expect(vacio['prestamos_total'], r'$0');
    expect(vacio['prestamos_cantidad'], 'Nadie te debe por ahora');
    expect(vacio['prestamos_nombre_0'], '');
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
