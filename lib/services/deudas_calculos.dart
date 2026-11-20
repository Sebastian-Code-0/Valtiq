import 'dart:math' as math;

import '../db/database.dart';
import '../utils/fecha_civil.dart';
import 'interes_calculator.dart';

/// Los números de UNA deuda tal como los muestra la pantalla de Deudas:
/// saldo de hoy, lo pagado, el pago mínimo, el próximo pago y la fecha
/// estimada en que se termina de pagar.
///
/// Todo sale de [InteresCalculator] (el mismo motor del detalle), así que
/// una tarjeta, el panel de detalle y el plan de pago nunca muestran cifras
/// distintas para la misma deuda.
class ResumenDeuda {
  ResumenDeuda._({
    required this.deuda,
    required this.abonos,
    required this.saldo,
    required this.abonado,
    required this.mesesTranscurridos,
  });

  /// [hoy] es la fecha local del dispositivo; solo se usa su día civil.
  factory ResumenDeuda.calcular(
    Deuda deuda,
    List<AbonoInteres> abonos, {
    required DateTime hoy,
  }) {
    final pagada = deuda.estado == 'pagada';
    // Una deuda pagada congela el interés en su fecha real de pago.
    final fin = pagada && deuda.fechaPagoReal != null
        ? fechaCivilGuardada(deuda.fechaPagoReal!)
        : normalizarFechaCivil(hoy);
    final abonado = abonos.fold<int>(0, (s, a) => s + a.monto);
    final resumen = InteresCalculator.resumenPrestamo(
      montoPrestado: deuda.montoOriginal,
      tasaInteres: deuda.tasaInteres,
      tipoInteres: deuda.tipoInteres,
      modalidadCalculo: deuda.modalidadCalculo,
      fechaPrestamo: deuda.fechaPrestamo,
      totalAbonado: abonado,
      tipoAmortizacion: deuda.tipoAmortizacion,
      abonos: abonos,
      fechaFin: fin,
    );
    return ResumenDeuda._(
      deuda: deuda,
      abonos: abonos,
      saldo: resumen['saldoPendiente']!,
      abonado: abonado,
      mesesTranscurridos: InteresCalculator.desglosarPeriodo(
        deuda.fechaPrestamo,
        fin,
      ).mesesTotal,
    );
  }

  final Deuda deuda;
  final List<AbonoInteres> abonos;

  /// Lo que falta por pagar hoy (capital + interés causado − abonos).
  final int saldo;

  /// Suma de todos los pagos registrados.
  final int abonado;

  /// Meses (con fracción) desde que empezó la deuda.
  final double mesesTranscurridos;

  /// Lo que la deuda vale en total: lo ya pagado más lo que falta.
  int get total => abonado + saldo;

  /// De 0.0 a 1.0: qué parte del total ya se pagó.
  double get fraccionPagada =>
      total > 0 ? (abonado / total).clamp(0.0, 1.0) : 0.0;

  bool get tieneInteres =>
      deuda.tasaInteres > 0 && deuda.tipoInteres != 'ninguno';

  /// Tasa del mes en porcentaje (una anual se divide entre 12, igual que en
  /// [InteresCalculator]).
  double get tasaMensualPct => !tieneInteres
      ? 0
      : (deuda.tipoInteres == 'anual'
            ? deuda.tasaInteres / 12
            : deuda.tasaInteres);

  /// Pago mínimo del mes: la cuota pactada, sin pasarse del saldo. `null`
  /// si la deuda no tiene cuota definida o ya no debe nada.
  int? get pagoMinimo {
    final cuota = deuda.cuotaMensual;
    if (cuota == null || cuota <= 0 || saldo <= 0) return null;
    return math.min(cuota, saldo);
  }

  /// Próxima fecha de pago: el siguiente día [Deuda.diaPago] del calendario
  /// (hoy incluido). Si el mes no tiene ese día (31 en febrero) cae en su
  /// último día. `null` si la deuda no tiene día de pago.
  DateTime? proximoPago(DateTime hoy) {
    final dia = deuda.diaPago;
    if (dia == null || saldo <= 0) return null;
    DateTime enMes(int anio, int mes) {
      final ultimo = DateTime(anio, mes + 1, 0).day;
      return DateTime(anio, mes, math.min(dia, ultimo));
    }

    final hoyCivil = DateTime(hoy.year, hoy.month, hoy.day);
    final esteMes = enMes(hoy.year, hoy.month);
    return esteMes.isBefore(hoyCivil)
        ? enMes(hoy.year, hoy.month + 1)
        : esteMes;
  }

  /// Fecha que muestra la tarjeta junto a "Vence": el próximo pago si hay
  /// día de pago; si no, la fecha límite de la deuda. `vencida` solo aplica
  /// a la fecha límite (un día de pago siempre apunta al futuro).
  ({DateTime fecha, bool vencida})? vencimiento(DateTime hoy) {
    final proximo = proximoPago(hoy);
    if (proximo != null) return (fecha: proximo, vencida: false);
    final limite = deuda.fechaLimite;
    if (limite == null) return null;
    final f = fechaCivilGuardada(limite);
    final fechaLocal = DateTime(f.year, f.month, f.day);
    return (
      fecha: fechaLocal,
      vencida: fechaLocal.isBefore(DateTime(hoy.year, hoy.month, hoy.day)),
    );
  }

  /// Cuánto paga esta persona al mes EN LA PRÁCTICA.
  ///
  /// Promedio de lo abonado en los últimos meses calendario completos
  /// (hasta 3, sin contar el mes en curso ni el mes en que empezó la deuda,
  /// que son parciales). Así, quien paga de más adelanta su fecha y quien
  /// paga de menos o se salta un mes la atrasa. Si todavía no hay meses
  /// completos que mirar, o no abonó nada en ellos, se asume la cuota
  /// pactada. `null` = no hay cómo estimar (sin historial y sin cuota).
  int? ritmoMensual(DateTime hoy) {
    final cuota = deuda.cuotaMensual;
    final inicio = fechaCivilGuardada(deuda.fechaPrestamo);
    final mesesCalendario =
        (hoy.year - inicio.year) * 12 + (hoy.month - inicio.month);
    final ventana = math.min(3, mesesCalendario - 1);
    if (ventana >= 1) {
      // [desde, hasta): del primer día de hace `ventana` meses al primer día
      // del mes en curso.
      final desde = DateTime.utc(hoy.year, hoy.month - ventana, 1);
      final hasta = DateTime.utc(hoy.year, hoy.month, 1);
      var suma = 0;
      for (final a in abonos) {
        final f = fechaCivilGuardada(a.fecha);
        if (!f.isBefore(desde) && f.isBefore(hasta)) suma += a.monto;
      }
      final promedio = InteresCalculator.aPesos(suma / ventana);
      if (promedio > 0) return promedio;
    }
    return (cuota != null && cuota > 0) ? cuota : null;
  }

  /// Interés que se causa en el mes número [k] contando desde hoy (k = 1 es
  /// el próximo mes) cuando al empezar ese mes se debe [saldoActual].
  ///
  /// Respeta cómo está configurada la deuda:
  /// - `saldo_insoluto`: sobre lo que falta por pagar.
  /// - `saldo_original` simple: siempre sobre el monto original.
  /// - `saldo_original` compuesto: sobre el monto original ya capitalizado.
  ///
  /// Aproximación documentada: en `saldo_insoluto` se toma todo el saldo
  /// como capital (si hay interés atrasado sin pagar, el estimado queda un
  /// poco por encima del real — nunca por debajo).
  double interesDelMes(int k, double saldoActual) {
    if (!tieneInteres || saldoActual <= 0) return 0;
    final i = tasaMensualPct / 100;
    if (deuda.tipoAmortizacion == 'saldo_insoluto') return saldoActual * i;
    if (deuda.modalidadCalculo == 'compuesto') {
      return deuda.montoOriginal *
          math.pow(1 + i, mesesTranscurridos + k - 1) *
          i;
    }
    return deuda.montoOriginal * i;
  }

  /// Interés del próximo mes como porcentaje de lo que se debe HOY: lo que
  /// de verdad cuesta cada peso de esta deuda. En `saldo_insoluto` es la
  /// tasa del mes; en `saldo_original` es más alto que la tasa, porque el
  /// interés se sigue cobrando sobre todo lo prestado aunque ya falte poco.
  /// Avalancha ordena por esto, no por la tasa escrita.
  double get costoMensualPct =>
      saldo <= 0 ? 0 : interesDelMes(1, saldo.toDouble()) / saldo * 100;

  /// La deuda empezó en el mes de [hoy].
  bool empezoEsteMes(DateTime hoy) {
    final inicio = fechaCivilGuardada(deuda.fechaPrestamo);
    return inicio.year == hoy.year && inicio.month == hoy.month;
  }

  /// Día del mes en que cae el [Deuda.diaPago] en ese mes (el último día si
  /// el mes es más corto). `null` si la deuda no tiene día de pago.
  int? _diaDePagoEn(int anio, int mes) {
    final dia = deuda.diaPago;
    if (dia == null) return null;
    return math.min(dia, DateTime(anio, mes + 1, 0).day);
  }

  /// El día de pago dentro del mes de [mes] (el último día si el mes es
  /// más corto). `null` si la deuda no tiene día de pago.
  DateTime? fechaDePagoEn(DateTime mes) {
    final dia = _diaDePagoEn(mes.year, mes.month);
    return dia == null ? null : DateTime(mes.year, mes.month, dia);
  }

  /// En el mes de [hoy] toca un pago. Siempre, salvo que la deuda haya
  /// empezado este mes: entonces solo si su día de pago de este mes cae
  /// después del día en que empezó (empezó el 12 y paga los 30 → sí; sin
  /// día de pago, el primer pago es el mes que viene).
  bool tienePagoEsteMes(DateTime hoy) {
    if (!empezoEsteMes(hoy)) return true;
    final dia = _diaDePagoEn(hoy.year, hoy.month);
    if (dia == null) return false;
    return dia > fechaCivilGuardada(deuda.fechaPrestamo).day;
  }

  /// El último mes (contando desde hoy, 0 = este mes) cuyo pago llega a
  /// tiempo para la fecha límite. Si el día de pago cae después del día
  /// límite en el mes del límite (límite el 15, paga los 30), ese mes ya
  /// no alcanza y cuenta el anterior. Negativo = el límite ya pasó (también
  /// si fue antes de hoy dentro de este mismo mes); `null` si no hay fecha
  /// límite.
  int? mesLimite(DateTime hoy) {
    final limite = deuda.fechaLimite;
    if (limite == null) return null;
    final l = fechaCivilGuardada(limite);
    // Se compara solo el día civil (año, mes, día): `l` viene en UTC y
    // `hoy` en hora local.
    if (DateTime(
      l.year,
      l.month,
      l.day,
    ).isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
      return -1;
    }
    var meses = (l.year - hoy.year) * 12 + l.month - hoy.month;
    final dia = _diaDePagoEn(l.year, l.month);
    if (meses > 0 && dia != null && dia > l.day) meses -= 1;
    return meses;
  }

  /// Suma de los pagos registrados en el mes de [hoy].
  int pagadoEsteMes(DateTime hoy) {
    var suma = 0;
    for (final a in abonos) {
      final f = fechaCivilGuardada(a.fecha);
      if (f.year == hoy.year && f.month == hoy.month) suma += a.monto;
    }
    return suma;
  }

  /// Lo que todavía falta pagar este mes para cumplir con [pagoDelMes]
  /// (lo ya pagado este mes se descuenta). Cero si este mes no toca pago
  /// ([tienePagoEsteMes]).
  int pendienteEsteMes(DateTime hoy, int? pagoDelMes) {
    if (pagoDelMes == null || pagoDelMes <= 0 || saldo <= 0) return 0;
    if (!tienePagoEsteMes(hoy)) return 0;
    // Lo pagado este mes ya bajó el saldo: lo que falta es el resto del
    // pago del mes, sin pasarse de lo que se debe.
    return math.max(0, math.min(pagoDelMes - pagadoEsteMes(hoy), saldo));
  }

  /// Lo pagado este mes por encima de la cuota: ya cuenta como el extra
  /// del mes en el plan de pago.
  int pagadoDeMasEsteMes(DateTime hoy) {
    final debido = tienePagoEsteMes(hoy) ? (deuda.cuotaMensual ?? 0) : 0;
    return math.max(0, pagadoEsteMes(hoy) - math.max(0, debido));
  }

  /// Cuándo se termina de pagar esta deuda si se sigue pagando al
  /// [ritmoMensual] de hoy.
  ///
  /// El mes en curso cuenta (mes 0): si el pago de este mes todavía no se
  /// hizo, se descuenta ya, sin sumar interés (el causado hasta hoy ya está
  /// en el saldo). Es la misma regla de [PlanPago.simular], así que con el
  /// mismo pago las dos fechas coinciden.
  LiquidacionEstimada liquidacionEstimada(DateTime hoy) {
    if (saldo <= 0) return const LiquidacionEstimada.sinDatos();
    final ritmo = ritmoMensual(hoy);
    if (ritmo == null) return const LiquidacionEstimada.sinDatos();
    return liquidacionCon(ritmo, hoy);
  }

  /// Cuándo se termina de pagar esta deuda pagando [pago] cada mes, con la
  /// misma regla del mes en curso de [liquidacionEstimada].
  LiquidacionEstimada liquidacionCon(int pago, DateTime hoy) {
    if (saldo <= 0 || pago <= 0) return const LiquidacionEstimada.sinDatos();
    var restante = saldo - pendienteEsteMes(hoy, pago).toDouble();
    if (restante < 0.5) {
      return LiquidacionEstimada._(
        fecha: DateTime(hoy.year, hoy.month, 1),
        meses: 0,
        noBaja: false,
        ritmo: pago,
      );
    }
    for (var k = 1; k <= mesesMaximosSimulacion; k++) {
      restante += interesDelMes(k, restante);
      restante -= math.min(pago.toDouble(), restante);
      if (restante < 0.5) {
        return LiquidacionEstimada._(
          fecha: DateTime(hoy.year, hoy.month + k, 1),
          meses: k,
          noBaja: false,
          ritmo: pago,
        );
      }
    }
    return LiquidacionEstimada._(
      fecha: null,
      meses: null,
      noBaja: true,
      ritmo: pago,
    );
  }

  /// Interés que se cobra el próximo mes con lo que se debe hoy: un pago
  /// que no lo supera no hace bajar la deuda.
  int get interesProximoMes =>
      InteresCalculator.aPesos(interesDelMes(1, saldo.toDouble()));

  /// La cuota más baja (en múltiplos de $1.000) con la que esta deuda
  /// queda en cero a más tardar en el mes [meses] contando desde hoy
  /// (0 = este mes). Usa el mismo motor que todo lo demás, así que respeta
  /// si el interés es sobre lo que falta o sobre lo prestado al inicio.
  /// `null` si ya no se debe nada.
  int? cuotaParaTerminarEn(int meses, DateTime hoy) {
    if (saldo <= 0) return null;
    // Si este mes no toca pago, lo antes que puede terminar es el mes que
    // viene.
    final objetivo = math.max(meses, tienePagoEsteMes(hoy) ? 0 : 1);
    bool alcanza(int unidades) {
      final l = liquidacionCon(unidades * _pasoCuota, hoy);
      return l.meses != null && l.meses! <= objetivo;
    }

    var alto = math.max(1, (saldo / _pasoCuota).ceil());
    // Con interés, pagar el saldo de hoy puede no alcanzar en el primer
    // mes: se dobla hasta que alcance.
    while (!alcanza(alto)) {
      if (alto > 1 << 40) return null; // no debería pasar; por si acaso.
      alto *= 2;
    }
    var bajo = 1;
    while (bajo < alto) {
      final medio = (bajo + alto) ~/ 2;
      if (alcanza(medio)) {
        alto = medio;
      } else {
        bajo = medio + 1;
      }
    }
    return bajo * _pasoCuota;
  }

  static const _pasoCuota = 1000;

  /// Las dos cuotas que la app sugiere para esta deuda:
  /// - **mínimo**: terminar en el plazo de [plazosSugeridos] según lo que
  ///   se debe, o antes de la fecha límite si esta llega primero;
  /// - **más rápido**: terminar en el plazo rápido (o en la mitad del plazo,
  ///   si la fecha límite llega antes). `null` si saldría igual que el
  ///   mínimo.
  ///
  /// Una fecha límite que ya pasó no cuenta (se usan los plazos normales).
  /// `null` si no se debe nada.
  SugerenciasCuota? sugerirCuotas(DateTime hoy) {
    if (saldo <= 0) return null;
    final base = plazosSugeridos(saldo);
    var plazo = base.minimo;
    var porLimite = false;
    final meses = mesLimite(hoy);
    if (meses != null) {
      if (meses >= 0 && meses <= plazo) {
        plazo = meses;
        porLimite = true;
      }
    }
    SugerenciaCuota sugerencia(int meses) {
      final cuota = cuotaParaTerminarEn(meses, hoy) ?? saldo;
      final l = liquidacionCon(cuota, hoy);
      return SugerenciaCuota(
        cuota: cuota,
        meses: l.meses ?? meses,
        fecha: l.fecha ?? DateTime(hoy.year, hoy.month + meses, 1),
      );
    }

    final minimo = sugerencia(plazo);
    final plazoRapido = plazo > base.rapido ? base.rapido : (plazo / 2).floor();
    final rapido = plazoRapido < plazo ? sugerencia(plazoRapido) : null;
    return SugerenciasCuota(
      minimo: minimo,
      rapido: rapido == null || rapido.cuota <= minimo.cuota ? null : rapido,
      porLimite: porLimite,
    );
  }
}

/// Plazos (en meses) de las cuotas que sugiere la app según lo que se debe
/// hoy (ver [ResumenDeuda.sugerirCuotas]): una deuda pequeña no se estira
/// años (100.000 en 3 años serían cuotas de $3.000, nada realista).
///
/// | Lo que se debe    | Mínimo | Más rápido |
/// |-------------------|--------|------------|
/// | hasta 500.000     | 6      | 3          |
/// | hasta 2.000.000   | 12     | 6          |
/// | hasta 10.000.000  | 24     | 12         |
/// | más               | 36     | 12         |
({int minimo, int rapido}) plazosSugeridos(int saldo) {
  if (saldo <= 500000) return (minimo: 6, rapido: 3);
  if (saldo <= 2000000) return (minimo: 12, rapido: 6);
  if (saldo <= 10000000) return (minimo: 24, rapido: 12);
  return (minimo: 36, rapido: 12);
}

class SugerenciaCuota {
  const SugerenciaCuota({
    required this.cuota,
    required this.meses,
    required this.fecha,
  });

  final int cuota;

  /// Meses desde hoy hasta quedar en cero (0 = este mes) y ese mes.
  final int meses;
  final DateTime fecha;
}

class SugerenciasCuota {
  const SugerenciasCuota({
    required this.minimo,
    required this.rapido,
    required this.porLimite,
  });

  final SugerenciaCuota minimo;
  final SugerenciaCuota? rapido;

  /// El mínimo está calculado para terminar antes de la fecha límite (y no
  /// a [plazoMinimoSugerido] meses).
  final bool porLimite;
}

/// Tope de la simulación mes a mes (50 años): más allá de eso se considera
/// que la deuda "no baja" con ese ritmo de pago.
const mesesMaximosSimulacion = 600;

class LiquidacionEstimada {
  const LiquidacionEstimada._({
    required this.fecha,
    required this.meses,
    required this.noBaja,
    required this.ritmo,
  });

  /// No hay cuota ni pagos con los que estimar.
  const LiquidacionEstimada.sinDatos()
    : fecha = null,
      meses = null,
      noBaja = false,
      ritmo = null;

  /// Mes en que se haría el último pago (día 1 de ese mes). `null` si no se
  /// puede estimar o si la deuda no baja.
  final DateTime? fecha;
  final int? meses;

  /// Con el ritmo actual el interés se come los pagos: la deuda no termina.
  final bool noBaja;

  /// Pago mensual con el que se hizo el cálculo.
  final int? ritmo;
}

/// Totales de la pestaña "Activas".
class TotalesDeudas {
  TotalesDeudas(List<ResumenDeuda> activas)
    : cantidad = activas.length,
      totalDeudas = activas.fold(0, (s, r) => s + r.saldo),
      pagosMinimosMes = activas.fold(0, (s, r) => s + (r.pagoMinimo ?? 0)),
      _abonado = activas.fold(0, (s, r) => s + r.abonado);

  final int cantidad;

  /// Suma de lo que falta por pagar en todas las deudas activas.
  final int totalDeudas;

  /// Suma de los pagos mínimos del mes (deudas sin cuota no suman).
  final int pagosMinimosMes;

  final int _abonado;

  /// De 0.0 a 1.0: lo ya pagado frente a todo lo que valen las deudas
  /// activas (pagado + pendiente).
  double get fraccionPagada {
    final total = _abonado + totalDeudas;
    return total > 0 ? (_abonado / total).clamp(0.0, 1.0) : 0.0;
  }
}

// ───────────────────────── Plan de pago ─────────────────────────

enum EstrategiaPago {
  avalancha(
    'avalancha',
    'Avalancha',
    'Primero la deuda con la tasa más alta. Pagas menos intereses en total.',
  ),
  bolaDeNieve(
    'bola_de_nieve',
    'Bola de nieve',
    'Primero la deuda más pequeña. Ves resultados rápido y eso anima a '
        'seguir.',
  );

  const EstrategiaPago(this.clave, this.nombre, this.resumen);

  /// Valor que se guarda en las preferencias.
  final String clave;
  final String nombre;
  final String resumen;

  static EstrategiaPago desdeClave(String? clave) =>
      values.firstWhere((e) => e.clave == clave, orElse: () => avalancha);
}

/// Las dos estrategias simuladas y cuál se usa. Ver [PlanPago.elegir].
class PlanElegido {
  const PlanElegido({
    required this.plan,
    required this.otra,
    required this.recomendada,
    required this.automatica,
  });

  /// El plan con la estrategia que se usa (la elegida, o la recomendada si
  /// el usuario dejó "Automática").
  final PlanPago plan;

  /// El mismo plan con la otra estrategia, para comparar.
  final PlanPago otra;

  final EstrategiaPago recomendada;

  /// El usuario no eligió: Valtiq usa la recomendada.
  final bool automatica;

  /// La recomendada cuesta casi lo mismo que la otra (ver
  /// [PlanPago.casiIgual]).
  bool get casiIgual => PlanPago.casiIgual(plan, otra);
}

/// Una deuda dentro del plan, en el orden en que se ataca.
class PasoPlan {
  const PasoPlan({
    required this.resumen,
    required this.meses,
    required this.fecha,
    this.pagoEsteMes = 0,
    this.pagoMesSiguiente = 0,
    this.mesLimite,
  });

  final ResumenDeuda resumen;

  /// Meses desde hoy hasta dejarla en cero (0 = este mes); `null` si con
  /// este plan no se termina nunca.
  final int? meses;

  /// Mes en que queda en cero (día 1 de ese mes).
  final DateTime? fecha;

  /// Lo que el plan le paga en el mes en curso (lo que falta, descontando
  /// lo ya pagado este mes) y en el siguiente.
  final int pagoEsteMes;
  final int pagoMesSiguiente;

  /// Meses desde hoy hasta su fecha límite (0 = este mes, negativo = ya
  /// pasó); `null` si no tiene fecha límite.
  final int? mesLimite;

  bool get termina => meses != null;

  /// La fecha límite ya pasó y la deuda sigue sin pagarse.
  bool get limiteVencido => mesLimite != null && mesLimite! < 0;

  /// Con este plan se termina después de la fecha límite (o nunca). No
  /// incluye las de límite vencido: esas ya no tienen arreglo.
  bool get tarde =>
      mesLimite != null &&
      !limiteVencido &&
      (meses == null || meses! > mesLimite!);
}

/// Cuánto extra al mes hace falta para algo (terminar, o llegar a tiempo a
/// las fechas límite) y en qué mes se quedaría libre con ese extra.
class SugerenciaExtra {
  const SugerenciaExtra({required this.extra, required this.fechaLibre});

  /// Extra TOTAL al mes (no lo que hay que sumar al que ya se puso).
  final int extra;
  final DateTime fechaLibre;
}

/// Qué pasaría pagando solo la cuota de cada deuda, sin extra y sin pasar
/// a otra deuda lo que se libera al terminar una.
class SoloMinimos {
  const SoloMinimos({required this.meses, required this.interesesTotales});

  /// `null` si así no se termina nunca (o alguna deuda no tiene cuota).
  final int? meses;
  final int interesesTotales;

  bool get termina => meses != null;
}

class PlanPago {
  const PlanPago({
    required this.estrategia,
    required this.presupuestoMensual,
    required this.meses,
    required this.fechaLibre,
    required this.interesesTotales,
    required this.orden,
    required this.soloMinimos,
    this.paraTerminar,
    this.paraLimites,
    this.saldoPorMes = const [],
  });

  final EstrategiaPago estrategia;

  /// Lo que se paga cada mes entre todas: pagos mínimos + extra. Cuando una
  /// deuda se termina, su pago mínimo se pasa a la siguiente (por eso el
  /// total del mes no baja).
  final int presupuestoMensual;

  /// Meses hasta quedar libre de deudas (0 = este mes); `null` si con ese
  /// presupuesto no se termina nunca (o no hay nada que pagar al mes).
  final int? meses;
  final DateTime? fechaLibre;

  /// Intereses que se pagarán de aquí al final del plan.
  final int interesesTotales;

  /// Deudas en orden de prioridad según la estrategia.
  final List<PasoPlan> orden;

  /// Lo mismo pagando solo los mínimos, para comparar.
  final SoloMinimos soloMinimos;

  /// Si el plan no alcanza: el extra mínimo con el que sí se termina.
  final SugerenciaExtra? paraTerminar;

  /// Si alguna deuda queda después de su fecha límite: el extra mínimo con
  /// el que todas llegan a tiempo (con esta misma estrategia).
  final SugerenciaExtra? paraLimites;

  /// Lo que se debe entre todas: hoy (posición 0) y al cerrar cada mes del
  /// plan (posición k + 1 = después del mes k; el mes 0 es el actual). Para
  /// la gráfica; vacío si no hay deudas.
  final List<int> saldoPorMes;

  bool get alcanza => meses != null;

  /// Deudas que con este plan nunca llegan a cero.
  List<PasoPlan> get sinTerminar => [
    for (final p in orden)
      if (!p.termina) p,
  ];

  /// Deudas que terminan después de su fecha límite.
  List<PasoPlan> get tarde => [
    for (final p in orden)
      if (p.tarde) p,
  ];

  /// Lo que hay que pagarle a cada deuda: este mes si todavía falta algo;
  /// si lo de este mes ya está pago, el mes siguiente. `esteMes` dice cuál.
  ({bool esteMes, List<(ResumenDeuda, int)> pagos}) get proximosPagos {
    final esteMes = orden.any((p) => p.pagoEsteMes > 0);
    return (
      esteMes: esteMes,
      pagos: [
        for (final p in orden)
          if ((esteMes ? p.pagoEsteMes : p.pagoMesSiguiente) > 0)
            (p.resumen, esteMes ? p.pagoEsteMes : p.pagoMesSiguiente),
      ],
    );
  }

  /// Simula el plan mes a mes.
  ///
  /// Mes 0 (el mes en curso): el interés causado hasta hoy ya está en el
  /// saldo; se paga lo que falte de la cuota de este mes (lo ya pagado se
  /// descuenta; una deuda que empezó este mes paga desde el siguiente) y lo
  /// que falte del extra.
  ///
  /// Cada mes siguiente: (1) a cada deuda se le suma su interés, (2) se paga
  /// el mínimo de todas, (3) lo que sobra del presupuesto (el extra más los
  /// mínimos de las deudas ya terminadas) va completo a la deuda prioritaria
  /// y, si alcanza para liquidarla, sigue con la siguiente.
  static PlanPago simular({
    required List<ResumenDeuda> deudas,
    required EstrategiaPago estrategia,
    required int extraMensual,
    required DateTime hoy,
  }) {
    final activas = deudas.where((r) => r.saldo > 0).toList();
    // Prioridad fija desde hoy, que es como se explica cada método. Para
    // avalancha cuenta lo que cuesta de verdad cada deuda, no la tasa
    // escrita (ver [ResumenDeuda.costoMensualPct]).
    activas.sort((a, b) {
      if (estrategia == EstrategiaPago.avalancha) {
        final porCosto = b.costoMensualPct.compareTo(a.costoMensualPct);
        return porCosto != 0 ? porCosto : a.saldo.compareTo(b.saldo);
      }
      final porSaldo = a.saldo.compareTo(b.saldo);
      return porSaldo != 0
          ? porSaldo
          : b.costoMensualPct.compareTo(a.costoMensualPct);
    });

    final extra = math.max<int>(0, extraMensual);
    final presupuesto =
        activas.fold<int>(0, (s, r) => s + (r.pagoMinimo ?? 0)) + extra;
    final corrida = _correr(activas, extra, hoy);
    final minimos = _correr(activas, 0, hoy, cascada: false);

    final limites = [for (final r in activas) r.mesLimite(hoy)];
    final orden = [
      for (var i = 0; i < activas.length; i++)
        PasoPlan(
          resumen: activas[i],
          meses: corrida.mesFin[i],
          fecha: _fechaDe(hoy, corrida.mesFin[i]),
          pagoEsteMes: InteresCalculator.aPesos(corrida.pagosEsteMes[i]),
          pagoMesSiguiente: InteresCalculator.aPesos(
            corrida.pagosMesSiguiente[i],
          ),
          mesLimite: limites[i],
        ),
    ];

    // Las búsquedas de extra solo se hacen cuando hay algo que arreglar.
    final tope = 2 * activas.fold<int>(0, (s, r) => s + r.saldo) + 1000;
    SugerenciaExtra? sugerir(bool Function(_Corrida c) cumple) {
      final x = _extraMinimo(
        (x) => cumple(_correr(activas, x, hoy)),
        desde: extra,
        tope: tope,
      );
      if (x == null) return null;
      return SugerenciaExtra(
        extra: x,
        fechaLibre: _fechaDe(hoy, _correr(activas, x, hoy).meses)!,
      );
    }

    // También exige terminar todo: un extra que deja a tiempo las deudas
    // con fecha límite pero con otra que nunca baja no es una solución.
    bool llegaATiempo(_Corrida c) {
      if (!c.termina) return false;
      for (var i = 0; i < activas.length; i++) {
        final l = limites[i];
        if (l == null || l < 0) continue;
        final fin = c.mesFin[i];
        if (fin == null || fin > l) return false;
      }
      return true;
    }

    final mesesTotales = corrida.meses;
    return PlanPago(
      estrategia: estrategia,
      presupuestoMensual: presupuesto,
      meses: mesesTotales,
      fechaLibre: activas.isEmpty ? null : _fechaDe(hoy, mesesTotales),
      interesesTotales: mesesTotales == null
          ? 0
          : InteresCalculator.aPesos(corrida.intereses),
      orden: orden,
      soloMinimos: SoloMinimos(
        meses: minimos.meses,
        interesesTotales: minimos.meses == null
            ? 0
            : InteresCalculator.aPesos(minimos.intereses),
      ),
      paraTerminar: activas.isEmpty || corrida.termina
          ? null
          : sugerir((c) => c.termina),
      paraLimites: orden.any((p) => p.tarde) ? sugerir(llegaATiempo) : null,
      saldoPorMes: activas.isEmpty
          ? const []
          : [for (final v in corrida.saldoTotal) InteresCalculator.aPesos(v)],
    );
  }

  /// Simula las dos estrategias y usa [elegida], o la recomendada si es
  /// `null` ("Automática").
  static PlanElegido elegir({
    required List<ResumenDeuda> deudas,
    required EstrategiaPago? elegida,
    required int extraMensual,
    required DateTime hoy,
  }) {
    PlanPago con(EstrategiaPago e) => simular(
      deudas: deudas,
      estrategia: e,
      extraMensual: extraMensual,
      hoy: hoy,
    );
    final avalancha = con(EstrategiaPago.avalancha);
    final bola = con(EstrategiaPago.bolaDeNieve);
    final recomendada = recomendar(avalancha, bola);
    final usada = elegida ?? recomendada;
    return PlanElegido(
      plan: usada == EstrategiaPago.avalancha ? avalancha : bola,
      otra: usada == EstrategiaPago.avalancha ? bola : avalancha,
      recomendada: recomendada,
      automatica: elegida == null,
    );
  }

  /// La estrategia que más conviene con estas deudas: la que termina (si
  /// solo una termina) o la que cobra menos intereses. Si cuestan casi lo
  /// mismo gana bola de nieve: terminar deudas pronto anima y no cuesta más.
  static EstrategiaPago recomendar(PlanPago avalancha, PlanPago bola) {
    if (avalancha.alcanza != bola.alcanza) {
      return avalancha.alcanza ? avalancha.estrategia : bola.estrategia;
    }
    if (!avalancha.alcanza) return EstrategiaPago.avalancha;
    if (casiIgual(avalancha, bola)) return EstrategiaPago.bolaDeNieve;
    return avalancha.interesesTotales <= bola.interesesTotales
        ? EstrategiaPago.avalancha
        : EstrategiaPago.bolaDeNieve;
  }

  /// Dos planes que terminan y cuyos intereses difieren en $1.000 o menos,
  /// o en menos del 1 %.
  static bool casiIgual(PlanPago a, PlanPago b) {
    if (!a.alcanza || !b.alcanza) return false;
    final diferencia = (a.interesesTotales - b.interesesTotales).abs();
    final mayor = math.max(a.interesesTotales, b.interesesTotales);
    return diferencia <= math.max(1000, mayor ~/ 100);
  }

  static DateTime? _fechaDe(DateTime hoy, int? meses) =>
      meses == null ? null : DateTime(hoy.year, hoy.month + meses, 1);

  /// El extra más pequeño (en múltiplos de $1.000, mayor que [desde]) con
  /// el que [cumple] es cierto; `null` si ni con [tope] se cumple. Más extra
  /// nunca atrasa ninguna deuda (el orden es fijo), así que se puede buscar
  /// por mitades.
  static int? _extraMinimo(
    bool Function(int extra) cumple, {
    required int desde,
    required int tope,
  }) {
    const paso = 1000;
    var bajo = desde ~/ paso + 1;
    var alto = (tope + paso - 1) ~/ paso;
    if (bajo > alto || !cumple(alto * paso)) return null;
    while (bajo < alto) {
      final medio = (bajo + alto) ~/ 2;
      if (cumple(medio * paso)) {
        alto = medio;
      } else {
        bajo = medio + 1;
      }
    }
    return bajo * paso;
  }

  /// La simulación en sí, con las deudas ya en orden. Con `cascada: false`
  /// cada deuda recibe solo su cuota (lo que se libera al terminar una no
  /// pasa a otra) y [extra] se ignora: es "pagar solo los mínimos".
  static _Corrida _correr(
    List<ResumenDeuda> orden,
    int extra,
    DateTime hoy, {
    bool cascada = true,
  }) {
    final n = orden.length;
    final saldos = [for (final r in orden) r.saldo.toDouble()];
    final mesFin = List<int?>.filled(n, null);
    final pagosEsteMes = List<double>.filled(n, 0);
    final pagosMesSiguiente = List<double>.filled(n, 0);
    final minimos = [for (final r in orden) (r.pagoMinimo ?? 0).toDouble()];
    final sumaMinimos = minimos.fold<double>(0, (s, m) => s + m);
    var intereses = 0.0;
    double total() => saldos.fold<double>(0, (s, v) => s + math.max(0, v));
    final saldoTotal = [total()];

    void pagarMes(
      int mes,
      List<double> minimosMes,
      double disponible,
      List<double>? registro,
    ) {
      // Mínimos primero…
      for (var i = 0; i < n; i++) {
        if (mesFin[i] != null) continue;
        final pago = math.min(minimosMes[i], saldos[i]);
        saldos[i] -= pago;
        disponible -= pago;
        registro?[i] += pago;
      }
      // …y lo que sobra, a la prioritaria (y a las que sigan).
      for (var i = 0; cascada && i < n && disponible > 0.5; i++) {
        if (mesFin[i] != null) continue;
        final pago = math.min(disponible, saldos[i]);
        saldos[i] -= pago;
        disponible -= pago;
        registro?[i] += pago;
      }
      for (var i = 0; i < n; i++) {
        if (mesFin[i] == null && saldos[i] < 0.5) mesFin[i] = mes;
      }
      saldoTotal.add(total());
    }

    // Mes 0: lo que falte de este mes.
    final pendientes = [
      for (final r in orden) r.pendienteEsteMes(hoy, r.pagoMinimo).toDouble(),
    ];
    final extraYaPagado = orden.fold<int>(
      0,
      (s, r) => s + r.pagadoDeMasEsteMes(hoy),
    );
    final extraPendiente = cascada ? math.max(0, extra - extraYaPagado) : 0;
    pagarMes(
      0,
      pendientes,
      pendientes.fold<double>(0, (s, p) => s + p) + extraPendiente,
      pagosEsteMes,
    );

    for (var k = 1; k <= mesesMaximosSimulacion; k++) {
      if (mesFin.every((m) => m != null)) break;
      for (var i = 0; i < n; i++) {
        if (mesFin[i] != null) continue;
        final interes = orden[i].interesDelMes(k, saldos[i]);
        saldos[i] += interes;
        intereses += interes;
      }
      pagarMes(
        k,
        minimos,
        sumaMinimos + (cascada ? extra : 0),
        k == 1 ? pagosMesSiguiente : null,
      );
    }
    return _Corrida(
      mesFin: mesFin,
      intereses: intereses,
      pagosEsteMes: pagosEsteMes,
      pagosMesSiguiente: pagosMesSiguiente,
      saldoTotal: saldoTotal,
    );
  }
}

class _Corrida {
  _Corrida({
    required this.mesFin,
    required this.intereses,
    required this.pagosEsteMes,
    required this.pagosMesSiguiente,
    required this.saldoTotal,
  });

  /// Mes en que cada deuda queda en cero (0 = este mes); `null` = nunca.
  final List<int?> mesFin;
  final double intereses;
  final List<double> pagosEsteMes;
  final List<double> pagosMesSiguiente;

  /// Total adeudado hoy y al cerrar cada mes simulado.
  final List<double> saldoTotal;

  bool get termina => mesFin.every((m) => m != null);

  /// Meses hasta terminar todas; 0 si no hay deudas; `null` si alguna no
  /// termina.
  int? get meses =>
      !termina ? null : mesFin.fold<int>(0, (s, m) => math.max(s, m!));
}
