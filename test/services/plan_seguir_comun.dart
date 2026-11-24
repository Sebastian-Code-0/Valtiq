// Ayudas de test/services/plan_seguir_test.dart: carteras realistas de
// Colombia y "seguir el plan" mes a mes con el calculador real.
import 'dart:math' as math;

import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/interes_calculator.dart';

DateTime civil(int a, int m, int d) => DateTime.utc(a, m, d);
int ultimoDia(int a, int m) => DateTime.utc(a, m + 1, 0).day;
String f10(DateTime? d) =>
    d == null ? 'null' : d.toIso8601String().substring(0, 10);

int _id = 0;
var semillaActual = 0;

class Cartera {
  Cartera(
    this.tipo,
    this.deudas,
    this.abonos,
    this.extra,
    this.estrategia,
    this.hoy0,
  ) : semilla = semillaActual;
  final int semilla;
  final String tipo;
  final List<Deuda> deudas;
  final Map<int, List<AbonoInteres>> abonos;
  final int extra;
  final EstrategiaPago? estrategia;
  final DateTime hoy0;
  String describir() => [
    '[$tipo semilla $semilla] hoy=${f10(hoy0)} extra=$extra est=${estrategia?.clave ?? 'auto'}',
    for (final d in deudas)
      '  #${d.id} ${d.acreedorNombre} ${d.montoOriginal} ${d.tasaInteres}${d.tipoInteres == 'anual'
              ? '%a'
              : d.tipoInteres == 'mensual'
              ? '%m'
              : ''} '
          '${d.modalidadCalculo}/${d.tipoAmortizacion} inicio=${f10(d.fechaPrestamo)} dia=${d.diaPago} cuota=${d.cuotaMensual} limite=${f10(d.fechaLimite)} '
          'abonos=${abonos[d.id]!.length}${abonos[d.id]!.isEmpty ? '' : ' ult=${f10(abonos[d.id]!.last.fecha)}:${abonos[d.id]!.last.monto}'}',
  ].join('\n');
}

int _redondearMil(num x) => ((x / 1000).ceil() * 1000).toInt();

int cuotaFija(int monto, double tasaMensualPct, int plazo) {
  final i = tasaMensualPct / 100;
  if (i == 0) return _redondearMil(monto / plazo);
  return _redondearMil(monto * i / (1 - math.pow(1 + i, -plazo)));
}

Deuda deuda({
  required String nombre,
  required int monto,
  required double tasa,
  String tipoInteres = 'mensual',
  String mod = 'simple',
  String am = 'saldo_insoluto',
  required DateTime inicio,
  int? dia,
  int? cuota,
  DateTime? limite,
}) => Deuda(
  id: ++_id,
  acreedorNombre: nombre,
  descripcion: '',
  tipo: 'otro',
  diaPago: dia,
  montoOriginal: monto,
  tasaInteres: tasa,
  tipoInteres: tasa == 0 ? 'ninguno' : tipoInteres,
  modalidadCalculo: mod,
  tipoAmortizacion: am,
  fechaPrestamo: inicio,
  fechaLimite: limite,
  cuotaMensual: cuota,
  notas: '',
  estado: 'activa',
  creadoEn: DateTime(2026),
  actualizadoEn: DateTime(2026),
);

/// Historial: pagó la cuota la mayoría de meses, en su día (o el del
/// inicio), a veces se saltó uno y a veces pagó de más.
List<AbonoInteres> historial(math.Random r, Deuda d, DateTime hoy0) {
  final lista = <AbonoInteres>[];
  final cuota = d.cuotaMensual;
  if (cuota == null) {
    if (r.nextInt(3) == 0) {
      lista.add(
        AbonoInteres(
          fecha: civil(hoy0.year, hoy0.month - 1, 10),
          monto: d.montoOriginal ~/ 10,
        ),
      );
    }
    return lista;
  }
  final ini = d.fechaPrestamo;
  final dia = d.diaPago ?? ini.day;
  for (var k = 1; k < 1000; k++) {
    final a = ini.year, m = ini.month + k;
    final f = civil(
      a,
      m,
      math.min(
        dia,
        ultimoDia(DateTime.utc(a, m).year, DateTime.utc(a, m).month),
      ),
    );
    if (!f.isBefore(civil(hoy0.year, hoy0.month, hoy0.day))) break;
    final p = r.nextInt(10);
    if (p == 0) continue; // se saltó
    lista.add(AbonoInteres(fecha: f, monto: p == 1 ? cuota * 2 : cuota));
  }
  return lista;
}

DateTime haceMeses(math.Random r, DateTime hoy0, int maxMeses) =>
    civil(hoy0.year, hoy0.month - r.nextInt(maxMeses + 1), 1 + r.nextInt(28));

List<Deuda> generar(String tipo, math.Random r, DateTime hoy0) {
  int? diaAzar() => r.nextInt(5) == 0
      ? null
      : [1, 5, 10, 15, 20, 25, 28, 30, 31][r.nextInt(9)];
  switch (tipo) {
    case 'amigo':
      final monto = [
        50000,
        100000,
        200000,
        500000,
        1000000,
        2000000,
      ][r.nextInt(6)];
      return [
        deuda(
          nombre: ['Mamá', 'Juan', 'Tía Rosa', 'Compañero'][r.nextInt(4)],
          monto: monto,
          tasa: r.nextInt(5) == 0 ? 2 : 0,
          am: 'saldo_original',
          inicio: haceMeses(r, hoy0, 6),
          dia: r.nextBool() ? null : diaAzar(),
          cuota: r.nextInt(4) == 0
              ? null
              : _redondearMil(monto / (2 + r.nextInt(10))),
          limite: r.nextInt(3) == 0
              ? civil(hoy0.year, hoy0.month + r.nextInt(12), 1 + r.nextInt(28))
              : null,
        ),
      ];
    case 'tarjeta':
      final monto = 500000 + r.nextInt(16) * 500000;
      final tasa = [1.8, 1.95, 2.1, 2.3, 2.4][r.nextInt(5)];
      return [
        deuda(
          nombre: [
            'Tarjeta Nu',
            'Visa Bancolombia',
            'Falabella CMR',
            'Mastercard Davivienda',
          ][r.nextInt(4)],
          monto: monto,
          tasa: tasa,
          mod: r.nextInt(3) == 0 ? 'simple' : 'compuesto',
          inicio: haceMeses(r, hoy0, 18),
          dia: [5, 10, 15, 20, 25, 30][r.nextInt(6)],
          cuota: cuotaFija(monto, tasa, [12, 24, 36][r.nextInt(3)]),
        ),
      ];
    case 'almacen':
      final monto = 800000 + r.nextInt(9) * 500000;
      final tasa = [1.9, 2.0, 2.2][r.nextInt(3)];
      return [
        deuda(
          nombre: 'Crédito almacén',
          monto: monto,
          tasa: tasa,
          mod: 'compuesto',
          inicio: haceMeses(r, hoy0, 12),
          dia: diaAzar() ?? 15,
          cuota: cuotaFija(monto, tasa, [12, 18, 24, 36][r.nextInt(4)]),
        ),
      ];
    case 'libre':
      final monto = 3000000 + r.nextInt(48) * 1000000;
      final tasa = [1.3, 1.5, 1.7, 1.9][r.nextInt(4)];
      return [
        deuda(
          nombre: 'Libre inversión',
          monto: monto,
          tasa: tasa,
          mod: r.nextBool() ? 'simple' : 'compuesto',
          inicio: haceMeses(r, hoy0, 24),
          dia: diaAzar() ?? 5,
          cuota: cuotaFija(monto, tasa, [24, 36, 48, 60, 72][r.nextInt(5)]),
        ),
      ];
    case 'carro':
      final monto = 40000000 + r.nextInt(9) * 10000000;
      final tasa = [1.1, 1.25, 1.4, 1.5][r.nextInt(4)];
      return [
        deuda(
          nombre: 'Crédito carro',
          monto: monto,
          tasa: tasa,
          inicio: haceMeses(r, hoy0, 30),
          dia: diaAzar() ?? 10,
          cuota: cuotaFija(monto, tasa, [60, 72, 84][r.nextInt(3)]),
        ),
      ];
    case 'icetex':
      final monto = 5000000 + r.nextInt(26) * 1000000;
      final tasa = [0.6, 0.8, 1.0][r.nextInt(3)];
      return [
        deuda(
          nombre: 'ICETEX',
          monto: monto,
          tasa: tasa,
          inicio: haceMeses(r, hoy0, 24),
          dia: 15,
          cuota: cuotaFija(monto, tasa, [60, 84, 120][r.nextInt(3)]),
        ),
      ];
    case 'gota':
      final monto = [200000, 500000, 1000000, 2000000, 3000000][r.nextInt(5)];
      final tasa = [10.0, 15.0, 20.0][r.nextInt(3)];
      final plazo = 2 + r.nextInt(5);
      return [
        deuda(
          nombre: 'Prestamista',
          monto: monto,
          tasa: tasa,
          am: 'saldo_original',
          inicio: haceMeses(r, hoy0, 2),
          dia: r.nextBool() ? null : diaAzar(),
          cuota: _redondearMil(monto * (1 + tasa / 100 * plazo) / plazo),
        ),
      ];
    case 'casa':
      final monto = 150000000 + r.nextInt(36) * 10000000;
      final anual = [11.0, 12.0, 12.5, 13.5, 14.0][r.nextInt(5)];
      final plazo = [180, 240, 360][r.nextInt(3)];
      return [
        deuda(
          nombre: 'Hipoteca',
          monto: monto,
          tasa: anual,
          tipoInteres: 'anual',
          mod: r.nextInt(3) == 0 ? 'compuesto' : 'simple',
          inicio: haceMeses(r, hoy0, 36),
          dia: diaAzar() ?? 5,
          cuota: cuotaFija(monto, anual / 12, plazo),
        ),
      ];
    case 'casa50':
      final monto = 200000000 + r.nextInt(31) * 10000000;
      final anual = [11.0, 12.0, 13.0][r.nextInt(3)];
      return [
        deuda(
          nombre: 'Hipoteca 50 años',
          monto: monto,
          tasa: anual,
          tipoInteres: 'anual',
          inicio: haceMeses(r, hoy0, 3),
          dia: diaAzar() ?? 1,
          cuota: cuotaFija(monto, anual / 12, 598),
        ),
      ];
  }
  throw ArgumentError(tipo);
}

const tiposPequenos = [
  'amigo',
  'tarjeta',
  'almacen',
  'gota',
  'icetex',
  'libre',
];

Cartera cartera(String esquema, math.Random r, DateTime hoy0) {
  final tipos = <String>[];
  switch (esquema) {
    case 'mixta':
      for (var i = 0; i < 2 + r.nextInt(6); i++) {
        tipos.add(tiposPequenos[r.nextInt(tiposPequenos.length)]);
      }
      if (r.nextInt(4) == 0) tipos.add('carro');
    case 'familia':
      for (var i = 0; i < 2 + r.nextInt(4); i++) {
        tipos.add('amigo');
      }
      if (r.nextBool()) tipos.add('tarjeta');
    case 'conCasa':
      tipos.add(r.nextInt(4) == 0 ? 'casa50' : 'casa');
      for (var i = 0; i < r.nextInt(4); i++) {
        tipos.add(['tarjeta', 'carro', 'libre', 'almacen'][r.nextInt(4)]);
      }
    default:
      tipos.add(esquema);
  }
  final deudas = [for (final t in tipos) ...generar(t, r, hoy0)];
  final abonos = {for (final d in deudas) d.id: historial(r, d, hoy0)};
  final extra = [0, 0, 50000, 100000, 300000, 1000000][r.nextInt(6)];
  final est = [
    null,
    null,
    EstrategiaPago.avalancha,
    EstrategiaPago.bolaDeNieve,
  ][r.nextInt(4)];
  return Cartera(esquema, deudas, abonos, extra, est, hoy0);
}

class Informe {
  int carteras = 0;
  int seguidasHastaElFinal = 0;
  int mesesSeguidos = 0;
  int pagos = 0;
  final problemas = <String, int>{};
  final ejemplos = <String, String>{};
  final lista = <String, List<String>>{};
  final difInteres = <double>[];
  final difMeses = <int>[];
  int cambiosFecha = 0;
  int maxMsPlan = 0;

  void problema(String tipo, Cartera c, String detalle) {
    problemas[tipo] = (problemas[tipo] ?? 0) + 1;
    ejemplos.putIfAbsent(tipo, () => '${c.describir()}\n  -> $detalle');
    if (!lista.containsKey(tipo)) lista[tipo] = [];
    if (lista[tipo]!.length < 12) {
      lista[tipo]!.add('${c.semilla}:${c.tipo}:${f10(c.hoy0)}:$detalle');
    }
  }

  String resumen() {
    difInteres.sort();
    String pct(double q) => difInteres.isEmpty
        ? '-'
        : (difInteres[(difInteres.length * q).floor().clamp(
                    0,
                    difInteres.length - 1,
                  )] *
                  100)
              .toStringAsFixed(3);
    return [
      'carteras $carteras, seguidas hasta el final $seguidasHastaElFinal, meses seguidos $mesesSeguidos, pagos $pagos, plan más lento ${maxMsPlan}ms',
      'intereses reales vs prometidos (%): mediana ${pct(.5)} p95 ${pct(.95)} p99 ${pct(.99)} max ${pct(1)}',
      'meses reales - prometidos: ${{for (final d in difMeses.toSet()) d: difMeses.where((x) => x == d).length}}',
      'cambios de fecha libre (mes a mes): $cambiosFecha',
      'problemas: $problemas',
      for (final e in ejemplos.entries)
        '\n### ${e.key}\n${e.value}\n  otros: ${lista[e.key]!.join(' | ')}',
    ].join('\n');
  }
}

/// Sigue el plan: el día [diaApertura] de cada mes (1 = el primero) abre la
/// app, paga lo de "Este mes paga" en el día de pago de cada deuda (o ese
/// mismo día si el de pago ya pasó) y acepta "Seguir pagándolos" al terminar una deuda.
void seguir(Cartera c, Informe inf, {int maxMeses = 700, int diaApertura = 1}) {
  inf.carteras++;
  final abonos = {
    for (final e in c.abonos.entries) e.key: [...e.value],
  };
  final terminada = <int>{};
  ResumenDeuda res(Deuda d, DateTime hoy) =>
      ResumenDeuda.calcular(d, abonos[d.id]!, hoy: hoy);
  final h0 = c.hoy0;
  final iniciales = {for (final d in c.deudas) d.id: res(d, h0).saldo};
  final activas = [
    for (final d in c.deudas)
      if (iniciales[d.id]! > 0) d,
  ];
  if (activas.isEmpty) return;
  var extra = c.extra;
  var pagado = 0;
  PlanPago? plan0;
  DateTime? fechaAnterior;
  int? mesReal;
  for (var m = 0; m < maxMeses; m++) {
    final hoy = m == 0
        ? h0
        : DateTime(
            h0.year,
            h0.month + m,
            math.min(diaApertura, ultimoDia(h0.year, h0.month + m)),
          );
    final vivas = [
      for (final d in activas)
        if (!terminada.contains(d.id)) d,
    ];
    if (vivas.isEmpty) {
      mesReal = m - 1;
      break;
    }
    final rs = [for (final d in vivas) res(d, hoy)];
    final reloj = Stopwatch()..start();
    final plan = PlanPago.elegir(
      deudas: rs,
      elegida: c.estrategia,
      extraMensual: extra,
      hoy: hoy,
      conSugerencias: m == 0,
    ).plan;
    inf.maxMsPlan = math.max(inf.maxMsPlan, reloj.elapsedMilliseconds);
    if (m == 0) {
      plan0 = plan;
      if (!plan.alcanza) return;
      fechaAnterior = plan.fechaLibre;
    } else if (diaApertura == 1 && plan.fechaLibre != fechaAnterior) {
      inf.cambiosFecha++;
      inf.problema(
        'fecha libre cambia de un mes a otro',
        c,
        'mes $m: ${f10(fechaAnterior)} -> ${f10(plan.fechaLibre)}',
      );
      fechaAnterior = plan.fechaLibre;
    }
    inf.mesesSeguidos++;
    for (final p in plan.orden) {
      final r = p.resumen;
      final d = r.deuda;
      final debe = r.faltaDelPagoEsteMes(hoy, d.cuotaMensual);
      final dia = d.diaPago ?? fechaCivilGuardadaLocal(d.fechaPrestamo).day;
      var f = civil(
        hoy.year,
        hoy.month,
        math.min(dia, ultimoDia(hoy.year, hoy.month)),
      );
      if (f.isBefore(civil(hoy.year, hoy.month, hoy.day))) {
        f = civil(hoy.year, hoy.month, hoy.day);
      }
      final fl = DateTime(f.year, f.month, f.day);
      final saldoDia = res(d, fl).saldo;
      final minimo = math.min(debe, saldoDia);
      if (p.pagoEsteMes + 1 < minimo) {
        inf.problema(
          'paga menos del mínimo',
          c,
          'mes $m ${d.acreedorNombre}: plan ${p.pagoEsteMes}, mínimo $minimo',
        );
      }
      if (p.pagoEsteMes <= 0) continue;
      var pago = p.pagoEsteMes;
      if (pago > saldoDia + 1) {
        inf.problema(
          'manda pagar más de lo que se debe',
          c,
          'mes $m ${d.acreedorNombre} el ${f10(f)}: plan $pago, debe $saldoDia',
        );
        pago = saldoDia;
      }
      abonos[d.id]!.add(AbonoInteres(fecha: f, monto: pago));
      pagado += pago;
      inf.pagos++;
      final despues = res(d, fl).saldo;
      if (p.meses == 0 && despues > 0) {
        inf.problema(
          despues == 1 ? 'último pago deja \$1' : 'último pago no alcanza',
          c,
          'mes $m ${d.acreedorNombre} el ${f10(f)}: plan $pago, quedan $despues',
        );
        // El usuario toca "Liquidar".
        abonos[d.id]!.add(AbonoInteres(fecha: f, monto: despues));
        pagado += despues;
      }
      if (res(d, fl).saldo <= 0) {
        terminada.add(d.id);
        extra += d.cuotaMensual ?? 0;
      }
    }
  }
  if (diaApertura != 1 || plan0 == null) return;
  if (mesReal == null) return; // no se siguió hasta el final
  inf.seguidasHastaElFinal++;
  inf.difMeses.add(mesReal - plan0.meses!);
  if (mesReal != plan0.meses) {
    inf.problema(
      'termina en otro mes',
      c,
      'plan ${plan0.meses}, real $mesReal',
    );
  }
  final real = pagado - iniciales.values.fold<int>(0, (s, v) => s + v);
  final pred = plan0.interesesTotales;
  final dif = pred == 0 ? (real == 0 ? 0.0 : 1.0) : (real - pred).abs() / pred;
  inf.difInteres.add(dif);
  if (dif > 0.005 && (real - pred).abs() > 1000) {
    inf.problema(
      'intereses distintos a lo prometido',
      c,
      'plan $pred, real $real',
    );
  }
}

DateTime fechaCivilGuardadaLocal(DateTime f) {
  final u = f.toUtc();
  return DateTime.utc(u.year, u.month, u.day);
}
