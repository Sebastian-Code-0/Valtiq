import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/services/plan_pago_preferencias.dart';

Deuda _pagada({
  int id = 1,
  int? cuota = 100000,
  required DateTime fechaPago,
  String estado = 'pagada',
}) => Deuda(
  id: id,
  acreedorNombre: 'A',
  descripcion: '',
  tipo: 'otro',
  montoOriginal: 100000,
  tasaInteres: 0,
  tipoInteres: 'ninguno',
  modalidadCalculo: 'simple',
  tipoAmortizacion: 'saldo_original',
  fechaPrestamo: DateTime.utc(2026, 9, 1),
  cuotaMensual: cuota,
  notas: '',
  estado: estado,
  fechaPagoReal: fechaPago,
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

void main() {
  final hoy = DateTime(2026, 11, 21);

  ResumenDeuda res(Deuda d) => ResumenDeuda.calcular(d, [
    AbonoInteres(fecha: DateTime.utc(2026, 11, 21), monto: 100000),
  ], hoy: hoy);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('ofrece solo deudas recientes con cuota', () async {
    final prefs = await PreferenciasPlan.leer();
    final l = prefs.cuotasLiberadas([
      res(_pagada(id: 1, fechaPago: DateTime.utc(2026, 11, 21))),
      res(_pagada(id: 2, fechaPago: DateTime.utc(2026, 10, 2))),
      res(_pagada(id: 3, fechaPago: DateTime.utc(2026, 9, 30))),
      res(_pagada(id: 4, cuota: null, fechaPago: DateTime.utc(2026, 11, 3))),
    ], hoy);
    expect(l.map((c) => c.deuda.id), [1, 2]);
    expect(l.first.diferidoEn(hoy), 100000);
    expect(l.last.diferidoEn(hoy), 0);
  });

  test('usarla suma al extra una sola vez y el aviso no vuelve', () async {
    await PreferenciasPlan.guardarExtra(20000);
    final r = res(_pagada(fechaPago: DateTime.utc(2026, 11, 21)));
    final c = (await PreferenciasPlan.leer()).cuotasLiberadas([r], hoy).single;
    await PreferenciasPlan.usarLiberada(c);
    final p = await PreferenciasPlan.usarLiberada(c);
    expect(p.extra, 120000);
    expect(p.extraDiferido(hoy), 100000);
    expect(p.extraDiferido(DateTime(2026, 12, 1)), 0);
    expect(p.cuotasLiberadas([r], hoy), isEmpty);
  });

  test('descartarla no toca el extra y el aviso no vuelve', () async {
    await PreferenciasPlan.guardarExtra(20000);
    final r = res(_pagada(fechaPago: DateTime.utc(2026, 11, 21)));
    final c = (await PreferenciasPlan.leer()).cuotasLiberadas([r], hoy).single;
    final p = await PreferenciasPlan.descartarLiberada(c);
    expect(p.extra, 20000);
    expect(p.extraDiferido(hoy), 0);
    expect(p.cuotasLiberadas([r], hoy), isEmpty);
  });

  test('si la deuda se reabre, su cuota sale del extra', () async {
    await PreferenciasPlan.guardarExtra(20000);
    final r = res(_pagada(fechaPago: DateTime.utc(2026, 11, 21)));
    final c = (await PreferenciasPlan.leer()).cuotasLiberadas([r], hoy).single;
    await PreferenciasPlan.usarLiberada(c);
    final p = await PreferenciasPlan.reconciliar({1});
    expect(p.extra, 20000);
    // Queda atendido: al volver a pagarla el aviso no se repite.
    expect(p.liberadas.single.monto, 0);
    expect(p.cuotasLiberadas([r], hoy), isEmpty);
    // Una segunda vez no resta otra vez.
    expect((await PreferenciasPlan.reconciliar({1})).extra, 20000);
  });

  test('el respaldo lleva los avisos atendidos', () async {
    final r = res(_pagada(fechaPago: DateTime.utc(2026, 11, 21)));
    final c = (await PreferenciasPlan.leer()).cuotasLiberadas([r], hoy).single;
    final json = (await PreferenciasPlan.usarLiberada(c)).toJson();
    SharedPreferences.setMockInitialValues({});
    await PreferenciasPlan.restaurar(json);
    final p = await PreferenciasPlan.leer();
    expect(p.extra, 100000);
    expect(p.cuotasLiberadas([r], hoy), isEmpty);
  });

  test(
    'un respaldo antiguo funciona y limpia los avisos de otras deudas',
    () async {
      final r = res(_pagada(fechaPago: DateTime.utc(2026, 11, 21)));
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([
        r,
      ], hoy).single;
      await PreferenciasPlan.usarLiberada(c);
      await PreferenciasPlan.restaurar({
        'estrategia': 'automatica',
        'extra': 5000,
      });
      final p = await PreferenciasPlan.leer();
      expect(p.extra, 5000);
      expect(p.liberadas, isEmpty);
    },
  );

  test('datos dañados no rompen la lectura', () async {
    SharedPreferences.setMockInitialValues({
      PreferenciasPlan.claveLiberadas: 'no es json',
    });
    expect((await PreferenciasPlan.leer()).liberadas, isEmpty);
  });
}
