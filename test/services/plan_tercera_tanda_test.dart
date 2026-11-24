import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/services/plan_pago_preferencias.dart';
import 'package:valtiq/utils/currency_input.dart';
import 'package:valtiq/utils/tasa_input.dart';

final _hoy = DateTime(2026, 11, 21);

Deuda _d({
  int id = 1,
  int monto = 1000000,
  double tasa = 0,
  String mod = 'simple',
  String am = 'saldo_original',
  required DateTime inicio,
  DateTime? limite,
  int? cuota,
  int? dia,
  String estado = 'activa',
  DateTime? pagada,
}) => Deuda(
  id: id,
  acreedorNombre: 'D$id',
  descripcion: '',
  tipo: 'otro',
  diaPago: dia,
  montoOriginal: monto,
  tasaInteres: tasa,
  tipoInteres: tasa > 0 ? 'mensual' : 'ninguno',
  modalidadCalculo: mod,
  tipoAmortizacion: am,
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: estado,
  fechaPagoReal: pagada,
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

ResumenDeuda _r(Deuda d, [List<AbonoInteres> a = const [], DateTime? hoy]) =>
    ResumenDeuda.calcular(d, a, hoy: hoy ?? _hoy);

AbonoInteres _a(int y, int m, int d, int monto) =>
    AbonoInteres(fecha: DateTime.utc(y, m, d), monto: monto);

PlanPago _plan(
  List<ResumenDeuda> rs,
  EstrategiaPago e,
  int extra, {
  bool sugerencias = true,
}) => PlanPago.simular(
  deudas: rs,
  estrategia: e,
  extraMensual: extra,
  hoy: _hoy,
  conSugerencias: sugerencias,
);

int _cumplidos(PlanPago p) => p.orden
    .where(
      (x) =>
          x.mesLimite != null &&
          x.mesLimite! >= 0 &&
          x.meses != null &&
          x.meses! <= x.mesLimite!,
    )
    .length;

List<ResumenDeuda> _azar(math.Random rnd) {
  final n = 2 + rnd.nextInt(4);
  return [
    for (var i = 0; i < n; i++)
      _r(
        _d(
          id: i + 1,
          monto: (3 + rnd.nextInt(60)) * 100000,
          tasa: rnd.nextBool() ? 0 : (1 + rnd.nextInt(60)) / 10,
          mod: rnd.nextBool() ? 'simple' : 'compuesto',
          am: rnd.nextBool() ? 'saldo_insoluto' : 'saldo_original',
          inicio: DateTime.utc(2026, 11 - rnd.nextInt(14), 1 + rnd.nextInt(27)),
          limite: rnd.nextInt(3) == 0
              ? null
              : DateTime.utc(2026, 12 + rnd.nextInt(24), 1 + rnd.nextInt(27)),
          dia: rnd.nextBool() ? 1 + rnd.nextInt(31) : null,
          cuota: (2 + rnd.nextInt(10)) * 50000,
        ),
      ),
  ];
}

/// Una deuda vencida o con fecha muy cerca terminó antes en [p] que en [a]:
/// esa prioridad puede costar algo de interés o alargar el plan, a propósito.
bool _urgenteAntes(PlanPago p, PlanPago a) {
  for (final x in p.orden) {
    final l = x.mesLimite;
    if (l == null || l > 3) continue;
    final y = a.orden.firstWhere(
      (o) => o.resumen.deuda.id == x.resumen.deuda.id,
    );
    if (x.meses != null && (y.meses == null || x.meses! < y.meses!)) {
      return true;
    }
  }
  return false;
}

void main() {
  group('C1 a C3: extra sugerido y fechas límite', () {
    test('C1: el caso reportado cumple al aplicar el extra', () {
      final rs = [
        _r(
          _d(
            id: 1,
            monto: 5000000,
            tasa: 8,
            mod: 'compuesto',
            inicio: DateTime.utc(2026, 11, 9),
            dia: 15,
            cuota: 200000,
          ),
        ),
        _r(
          _d(
            id: 2,
            monto: 3000000,
            tasa: 8,
            mod: 'compuesto',
            am: 'saldo_insoluto',
            inicio: DateTime.utc(2025, 9, 16),
            dia: 15,
            cuota: 210000,
            limite: DateTime.utc(2027, 6, 23),
          ),
        ),
      ];
      for (final e in EstrategiaPago.values) {
        final s = _plan(rs, e, 0).paraLimites!;
        final con = _plan(rs, e, s.extra, sugerencias: false);
        expect(con.alcanza, isTrue);
        expect(con.tarde, isEmpty);
        expect(con.fechaLibre, s.fechaLibre);
        final menos = _plan(rs, e, s.extra - 1000, sugerencias: false);
        expect(menos.alcanza && menos.tarde.isEmpty, isFalse);
      }
    });

    test('C1: el extra sugerido siempre cumple y mil pesos menos no', () {
      final rnd = math.Random(41);
      var revisados = 0;
      for (var c = 0; c < 400; c++) {
        final rs = _azar(rnd);
        for (final e in EstrategiaPago.values) {
          final base = _plan(rs, e, 0);
          for (final s in [base.paraLimites, base.paraTerminar]) {
            if (s == null) continue;
            revisados++;
            bool cumple(PlanPago p) => identical(s, base.paraLimites)
                ? p.alcanza && p.tarde.isEmpty
                : p.alcanza;
            final con = _plan(rs, e, s.extra, sugerencias: false);
            expect(cumple(con), isTrue, reason: 'caso $c ${e.name}');
            expect(con.fechaLibre, s.fechaLibre, reason: 'caso $c');
            if (s.extra >= 1000) {
              final menos = _plan(rs, e, s.extra - 1000, sugerencias: false);
              expect(cumple(menos), isFalse, reason: 'caso $c ${e.name}');
            }
          }
        }
      }
      expect(revisados, greaterThan(100));
    });

    test('C2: Avalancha cumple al menos tantas fechas como cualquier '
        'estrategia y, cumpliendo igual, no cobra más', () {
      final rnd = math.Random(43);
      for (var c = 0; c < 300; c++) {
        final rs = _azar(rnd);
        final x = rnd.nextInt(5) * 100000;
        final av = _plan(rs, EstrategiaPago.avalancha, x, sugerencias: false);
        final bo = _plan(rs, EstrategiaPago.bolaDeNieve, x, sugerencias: false);
        if (!bo.alcanza) continue;
        expect(av.alcanza, isTrue, reason: 'caso $c');
        expect(
          _cumplidos(av),
          greaterThanOrEqualTo(_cumplidos(bo)),
          reason: 'caso $c',
        );
        if (_cumplidos(av) == _cumplidos(bo)) {
          expect(
            av.interesesTotales,
            lessThanOrEqualTo(bo.interesesTotales + 1),
            reason: 'caso $c',
          );
        }
      }
    });

    test('C3: más extra no encarece sin cumplir más fechas', () {
      final rnd = math.Random(47);
      for (var c = 0; c < 200; c++) {
        final rs = _azar(rnd);
        for (final e in EstrategiaPago.values) {
          PlanPago? antes;
          for (final x in [0, 50000, 100000, 200000, 400000, 800000]) {
            final p = _plan(rs, e, x, sugerencias: false);
            final a = antes;
            if (a != null && a.alcanza) {
              expect(p.alcanza, isTrue, reason: 'caso $c $x');
              expect(_cumplidos(p), greaterThanOrEqualTo(_cumplidos(a)));
              if (_cumplidos(p) == _cumplidos(a) && !_urgenteAntes(p, a)) {
                expect(
                  p.interesesTotales,
                  lessThanOrEqualTo(a.interesesTotales + 1),
                  reason: 'caso $c ${e.name} $x',
                );
              }
            }
            antes = p;
          }
        }
      }
    });

    test('C4: 12 deudas con límite lejano no bloquean la pantalla', () {
      final rs = [
        for (var i = 0; i < 12; i++)
          _r(
            _d(
              id: i + 1,
              monto: 9000000 + i * 700000,
              tasa: 1 + (i % 6) * 0.4,
              mod: i % 3 == 0 ? 'compuesto' : 'simple',
              am: i.isEven ? 'saldo_insoluto' : 'saldo_original',
              inicio: DateTime.utc(2026, 8, 1),
              limite: DateTime.utc(2036, 1 + i, 20),
              dia: 5 + i,
              cuota: 95000 + i * 5000,
            ),
          ),
      ];
      final reloj = Stopwatch()..start();
      PlanPago.elegir(deudas: rs, elegida: null, extraMensual: 0, hoy: _hoy);
      // Con margen sobre lo medido, para no fallar en una máquina cargada.
      expect(reloj.elapsedMilliseconds, lessThan(1000));
    });
  });

  test('C5: Liquidar antes de un pago posterior deja en cero', () {
    final d = _d(
      tasa: 2,
      am: 'saldo_insoluto',
      inicio: DateTime.utc(2026, 1, 1),
    );
    final abonos = [_a(2026, 9, 11, 100000)];
    final monto = _r(d, abonos).saldoAl(DateTime(2026, 9, 1));
    final todos = [...abonos, _a(2026, 9, 1, monto)];
    expect(_r(d, todos, DateTime(2026, 9, 11)).saldo, 0);
    // Con un peso menos todavía se debe algo: es el monto exacto.
    expect(
      _r(d, [
        ...abonos,
        _a(2026, 9, 1, monto - 1),
      ], DateTime(2026, 9, 11)).saldo,
      greaterThan(0),
    );
  });

  group('C6: exactamente N pagos', () {
    int pagosCon(ResumenDeuda r, int cuota) {
      var saldo = r.saldo;
      var pagos = 0;
      final resto = math.max(0, cuota - r.pagadoEsteMes(_hoy));
      if (resto > 0) {
        saldo -= math.min(resto, saldo);
        pagos++;
      }
      while (saldo > 0) {
        saldo -= math.min(cuota, saldo);
        pagos++;
      }
      return pagos;
    }

    for (final abono in [50000, 10000]) {
      test('abono de $abono este mes', () {
        final r = _r(
          _d(monto: 1200000 + abono, inicio: DateTime.utc(2026, 8, 1)),
          [_a(2026, 11, 21, abono)],
        );
        final c = r.cuotaParaPagos(12, _hoy)!.cuota;
        expect(pagosCon(r, c), 12);
        expect(pagosCon(r, c - 1000), greaterThan(12));
      });
    }

    test('si la cuota no pasa de lo abonado, empiezan el mes que viene', () {
      final r = _r(_d(monto: 1300000, inicio: DateTime.utc(2026, 8, 1)), [
        _a(2026, 11, 5, 100000),
      ]);
      expect(r.cuotaParaPagos(12, _hoy)!.cuota, 100000);
    });
  });

  test('C7: día 30 sobre lo prestado coincide con pagar de verdad', () {
    final hoy = DateTime(2026, 12, 1);
    final d = _d(
      monto: 300000,
      tasa: 3,
      inicio: DateTime.utc(2026, 4, 30),
      dia: 30,
      cuota: 12000,
    );
    final r = _r(d, const [], hoy);
    final p = PlanPago.simular(
      deudas: [r],
      estrategia: EstrategiaPago.avalancha,
      extraMensual: 0,
      hoy: hoy,
    );
    // Lo real: pagar la cuota cada día 30 con el motor.
    final abonos = <AbonoInteres>[];
    var pagado = 0;
    int? real;
    for (var k = 0; k < 300; k++) {
      final ultimo = DateTime.utc(2026, 12 + k + 1, 0).day;
      final f = DateTime.utc(2026, 12 + k, math.min(30, ultimo));
      final s = _r(d, abonos, DateTime(f.year, f.month, f.day)).saldo;
      final x = math.min(12000, s);
      abonos.add(AbonoInteres(fecha: f, monto: x));
      pagado += x;
      if (s - x <= 0) {
        real = k;
        break;
      }
    }
    expect(p.meses, real);
    expect(r.saldo + p.interesesTotales, closeTo(pagado, 1000));
  });

  test('C8: tasas muy pequeñas no se pierden', () {
    for (final t in [1e-13, 1.5e-9, 2.5e-7]) {
      final texto = tasaParaCampo(t);
      expect(texto, isNot(contains('e')));
      expect(parseTasa(texto), t);
    }
  });

  group('D: cuotas liberadas', () {
    final pagadaHoy = _r(
      _d(
        monto: 100000,
        inicio: DateTime.utc(2026, 9, 1),
        cuota: 100000,
        estado: 'pagada',
        pagada: DateTime.utc(2026, 11, 20),
      ),
      [_a(2026, 11, 20, 100000)],
    );

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('D2: volver a pagarla otro día no repite el aviso', () async {
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([
        pagadaHoy,
      ], _hoy).single;
      final p = await PreferenciasPlan.usarLiberada(c);
      final otraFecha = _r(
        pagadaHoy.deuda.copyWith(
          fechaPagoReal: Value(DateTime.utc(2026, 11, 21)),
        ),
        pagadaHoy.abonos,
      );
      expect(p.cuotasLiberadas([otraFecha], _hoy), isEmpty);
      expect(p.extra, 100000);
    });

    test('D2: un respaldo sin plan no repite el aviso', () async {
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([
        pagadaHoy,
      ], _hoy).single;
      await PreferenciasPlan.usarLiberada(c);
      await PreferenciasPlan.restaurar(null);
      final p = await PreferenciasPlan.leer();
      expect(p.extra, 100000);
      expect(p.cuotasLiberadas([pagadaHoy], _hoy), isEmpty);
    });

    test('D3: si el usuario escribió otro extra, reabrir no lo toca', () async {
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([
        pagadaHoy,
      ], _hoy).single;
      await PreferenciasPlan.usarLiberada(c);
      await PreferenciasPlan.guardarExtra(30000);
      final p = await PreferenciasPlan.reconciliar({1});
      expect(p.extra, 30000);
      expect(p.liberadas.single.monto, 0);
    });

    test('D1: mientras se restaura no se ajusta nada', () async {
      final c = (await PreferenciasPlan.leer()).cuotasLiberadas([
        pagadaHoy,
      ], _hoy).single;
      await PreferenciasPlan.usarLiberada(c);
      PreferenciasPlan.restaurando++;
      addTearDown(() => PreferenciasPlan.restaurando--);
      final p = await PreferenciasPlan.reconciliar({1});
      expect(p.extra, 100000);
      expect(p.liberadas, hasLength(1));
    });
  });

  test(
    'D4: el mensaje al eliminar un pago es el saldo de la tarjeta',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final ahora = DateTime.now();
      final inicio = DateTime.utc(ahora.year, ahora.month - 6, 1);
      final pagoF = DateTime.utc(ahora.year, ahora.month - 2, 1);
      final id = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'X',
          montoOriginal: 1000000,
          tasaInteres: const Value(3),
          tipoInteres: const Value('mensual'),
          fechaPrestamo: inicio,
        ),
      );
      await db.pagosDeudaDao.insertPago(
        PagosDeudaCompanion.insert(
          deudaId: id,
          montoAbonado: 1120000,
          fechaPago: pagoF,
        ),
      );
      await db.deudasDao.marcarComoPagada(id, pagoF);
      final ps = await db.pagosDeudaDao.getPagosDeDeuda(id);
      final debe = await db.pagosDeudaDao.eliminarPago(ps.first.id);
      final d = (await db.deudasDao.getDeudaById(id))!;
      expect(debe, ResumenDeuda.calcular(d, const [], hoy: ahora).saldo);
    },
  );

  group('E1: campos de monto', () {
    final f = CopInputFormatter();
    String pegar(String t) => f
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: t))
        .text;

    String teclear(String t) {
      var v = TextEditingValue.empty;
      for (final ch in t.split('')) {
        final n = v.text + ch;
        v = f.formatEditUpdate(
          v,
          TextEditingValue(
            text: n,
            selection: TextSelection.collapsed(offset: n.length),
          ),
        );
      }
      return v.text;
    }

    test('al teclear, coma y punto no hacen nada', () {
      expect(teclear('1500000,50'), '150.000.050');
      expect(teclear('1.500.000'), '1.500.000');
      expect(teclear('2000'), '2.000');
    });

    test('una coma en medio no borra dígitos', () {
      const viejo = TextEditingValue(
        text: '1.000.000',
        selection: TextSelection.collapsed(offset: 5),
      );
      final v = f.formatEditUpdate(
        viejo,
        const TextEditingValue(
          text: '1.000,.000',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      expect(v.text, '1.000.000');
    });

    test('pegar nunca multiplica ni divide', () {
      expect(pegar('999.999.999.999,5'), '999.999.999.999');
      expect(pegar(',9'), '');
      expect(pegar('1.500.000,50'), '1.500.000');
      expect(pegar('0,4'), '0');
    });

    test('lo que no es un monto se rechaza sin cambiar el valor', () {
      const viejo = TextEditingValue(
        text: '5.000',
        selection: TextSelection.collapsed(offset: 5),
      );
      for (final t in ['1e5', '-5000', 'abc']) {
        final v = f.formatEditUpdate(
          viejo,
          TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          ),
        );
        expect(v.text, '5.000', reason: t);
      }
    });

    test('editar en medio conserva el cursor', () {
      const viejo = TextEditingValue(
        text: '1.234.567',
        selection: TextSelection.collapsed(offset: 1),
      );
      final v = f.formatEditUpdate(
        viejo,
        const TextEditingValue(
          text: '19.234.567',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(v.text, '19.234.567');
      expect(v.selection.baseOffset, 2);
    });

    test('borrar un punto de miles borra el dígito de al lado', () {
      const viejo = TextEditingValue(
        text: '1.234',
        selection: TextSelection.collapsed(offset: 2),
      );
      final v = f.formatEditUpdate(
        viejo,
        const TextEditingValue(
          text: '1234',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      expect(v.text, '234');
    });
  });

  test('E3: el tope de un abono usa el saldo de esa fecha', () {
    final m = InteresCalculator.montoParaLiquidar(
      montoPrestado: 1000000,
      tasaInteres: 3,
      tipoInteres: 'mensual',
      modalidadCalculo: 'simple',
      fechaPrestamo: DateTime.utc(2026, 8, 21),
      tipoAmortizacion: 'saldo_insoluto',
      abonos: const [],
      fecha: DateTime.utc(2026, 11, 1),
    );
    expect(m, 1071000);
  });
}
