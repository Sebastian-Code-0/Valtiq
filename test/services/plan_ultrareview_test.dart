import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/services/plan_pago_preferencias.dart';

// Hallazgos de la revisión en la nube del Plan de pago (2026-11-24).

Deuda _d({
  int id = 1,
  int monto = 300000,
  int? cuota = 100000,
  int? dia,
  required DateTime inicio,
  DateTime? limite,
  String estado = 'activa',
  DateTime? pagada,
}) => Deuda(
  id: id,
  acreedorNombre: 'D$id',
  descripcion: '',
  tipo: 'otro',
  diaPago: dia,
  montoOriginal: monto,
  tasaInteres: 0,
  tipoInteres: 'ninguno',
  modalidadCalculo: 'simple',
  tipoAmortizacion: 'saldo_original',
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: estado,
  fechaPagoReal: pagada,
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

void main() {
  final hoy = DateTime(2026, 11, 21);

  test('con extra ya usado este mes y un límite este mes, el extra sugerido '
      'existe y cumple', () {
    final b = ResumenDeuda.calcular(
      _d(
        inicio: DateTime.utc(2026, 10, 28),
        dia: 28,
        limite: DateTime.utc(2026, 11, 28),
      ),
      const [],
      hoy: hoy,
    );
    // "Seguir pagándolos" con una cuota de $500.000 que ya se pagó este mes.
    final plan = PlanPago.simular(
      deudas: [b],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 500000,
      extraDiferido: 500000,
      hoy: hoy,
    );
    expect(plan.fechasIncumplidas, 1);
    final s = plan.paraLimites;
    expect(s, isNotNull);
    final con = PlanPago.simular(
      deudas: [b],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: s!.extra,
      extraDiferido: 500000,
      hoy: hoy,
    );
    expect(con.fechasIncumplidas, 0);
  });

  group('cuotas liberadas', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<void> seguirPagando() async {
      final r = ResumenDeuda.calcular(
        _d(
          inicio: DateTime.utc(2026, 9, 1),
          monto: 100000,
          estado: 'pagada',
          pagada: DateTime.utc(2026, 11, 21),
        ),
        [AbonoInteres(fecha: DateTime.utc(2026, 11, 21), monto: 100000)],
        hoy: hoy,
      );
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([r], hoy);
      await PreferenciasPlan.usarLiberada(c.single);
    }

    test(
      'un botón "+\$X" no impide sacar la cuota del extra al reabrir',
      () async {
        await PreferenciasPlan.guardarExtra(20000);
        await seguirPagando();
        // 120.000 + 50.000 del botón.
        await PreferenciasPlan.guardarExtra(170000, escritoPorUsuario: false);
        final p = await PreferenciasPlan.reconciliar({1});
        expect(p.extra, 70000);
      },
    );

    test('lo que escribe el usuario sí manda', () async {
      await PreferenciasPlan.guardarExtra(20000);
      await seguirPagando();
      await PreferenciasPlan.guardarExtra(170000);
      final p = await PreferenciasPlan.reconciliar({1});
      expect(p.extra, 170000);
    });

    test('un respaldo sin plan conserva el extra, pero sus avisos ya no le '
        'restan cuotas de otras deudas', () async {
      await PreferenciasPlan.guardarExtra(20000);
      await seguirPagando();
      await PreferenciasPlan.restaurar(null);
      // El id 1 ahora es otra deuda, activa.
      final p = await PreferenciasPlan.reconciliar({1});
      expect(p.extra, 120000);
    });
  });
}
