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

  /// Cuándo se termina de pagar esta deuda si se sigue pagando al
  /// [ritmoMensual] de hoy.
  LiquidacionEstimada liquidacionEstimada(DateTime hoy) {
    if (saldo <= 0) return const LiquidacionEstimada.sinDatos();
    final ritmo = ritmoMensual(hoy);
    if (ritmo == null) return const LiquidacionEstimada.sinDatos();
    var restante = saldo.toDouble();
    for (var k = 1; k <= mesesMaximosSimulacion; k++) {
      restante += interesDelMes(k, restante);
      restante -= math.min(ritmo.toDouble(), restante);
      if (restante < 0.5) {
        return LiquidacionEstimada._(
          fecha: DateTime(hoy.year, hoy.month + k, 1),
          meses: k,
          noBaja: false,
          ritmo: ritmo,
        );
      }
    }
    return LiquidacionEstimada._(
      fecha: null,
      meses: null,
      noBaja: true,
      ritmo: ritmo,
    );
  }
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

/// Una deuda dentro del plan, en el orden en que se ataca.
class PasoPlan {
  const PasoPlan({
    required this.resumen,
    required this.meses,
    required this.fecha,
  });

  final ResumenDeuda resumen;

  /// Meses desde hoy hasta dejarla en cero; `null` si el plan no alcanza.
  final int? meses;
  final DateTime? fecha;
}

class PlanPago {
  const PlanPago({
    required this.estrategia,
    required this.presupuestoMensual,
    required this.meses,
    required this.fechaLibre,
    required this.interesesTotales,
    required this.orden,
  });

  final EstrategiaPago estrategia;

  /// Lo que se paga cada mes entre todas: pagos mínimos + extra. Cuando una
  /// deuda se termina, su pago mínimo se pasa a la siguiente (por eso el
  /// total del mes no baja).
  final int presupuestoMensual;

  /// Meses hasta quedar libre de deudas; `null` si con ese presupuesto no
  /// se termina nunca (o no hay nada que pagar al mes).
  final int? meses;
  final DateTime? fechaLibre;

  /// Intereses que se pagarán de aquí al final del plan.
  final int interesesTotales;

  /// Deudas en orden de prioridad según la estrategia.
  final List<PasoPlan> orden;

  bool get alcanza => meses != null;

  /// Simula el plan mes a mes.
  ///
  /// Cada mes: (1) a cada deuda se le suma su interés, (2) se paga el mínimo
  /// de todas, (3) lo que sobra del presupuesto (el extra más los mínimos de
  /// las deudas ya terminadas) va completo a la deuda prioritaria y, si
  /// alcanza para liquidarla, sigue con la siguiente.
  static PlanPago simular({
    required List<ResumenDeuda> deudas,
    required EstrategiaPago estrategia,
    required int extraMensual,
    required DateTime hoy,
  }) {
    final activas = deudas.where((r) => r.saldo > 0).toList();
    // Prioridad fija desde hoy, que es como se explica cada método.
    activas.sort((a, b) {
      if (estrategia == EstrategiaPago.avalancha) {
        final porTasa = b.tasaMensualPct.compareTo(a.tasaMensualPct);
        return porTasa != 0 ? porTasa : a.saldo.compareTo(b.saldo);
      }
      final porSaldo = a.saldo.compareTo(b.saldo);
      return porSaldo != 0
          ? porSaldo
          : b.tasaMensualPct.compareTo(a.tasaMensualPct);
    });

    final presupuesto =
        activas.fold<int>(0, (s, r) => s + (r.pagoMinimo ?? 0)) +
        math.max<int>(0, extraMensual);
    final saldos = [for (final r in activas) r.saldo.toDouble()];
    final mesFin = List<int?>.filled(activas.length, null);
    var intereses = 0.0;
    int? mesesTotales;

    if (activas.isEmpty) {
      mesesTotales = 0;
    } else if (presupuesto > 0) {
      for (var k = 1; k <= mesesMaximosSimulacion; k++) {
        for (var i = 0; i < activas.length; i++) {
          if (mesFin[i] != null) continue;
          final interes = activas[i].interesDelMes(k, saldos[i]);
          saldos[i] += interes;
          intereses += interes;
        }
        var disponible = presupuesto.toDouble();
        // Mínimos primero…
        for (var i = 0; i < activas.length; i++) {
          if (mesFin[i] != null) continue;
          final pago = math.min(
            (activas[i].pagoMinimo ?? 0).toDouble(),
            saldos[i],
          );
          saldos[i] -= pago;
          disponible -= pago;
        }
        // …y lo que sobra, a la prioritaria (y a las que sigan).
        for (var i = 0; i < activas.length && disponible > 0.5; i++) {
          if (mesFin[i] != null) continue;
          final pago = math.min(disponible, saldos[i]);
          saldos[i] -= pago;
          disponible -= pago;
        }
        for (var i = 0; i < activas.length; i++) {
          if (mesFin[i] == null && saldos[i] < 0.5) mesFin[i] = k;
        }
        if (mesFin.every((m) => m != null)) {
          mesesTotales = k;
          break;
        }
      }
    }

    DateTime? fechaDe(int? meses) =>
        meses == null ? null : DateTime(hoy.year, hoy.month + meses, 1);

    return PlanPago(
      estrategia: estrategia,
      presupuestoMensual: presupuesto,
      meses: mesesTotales,
      fechaLibre: activas.isEmpty ? null : fechaDe(mesesTotales),
      interesesTotales: mesesTotales == null
          ? 0
          : InteresCalculator.aPesos(intereses),
      orden: [
        for (var i = 0; i < activas.length; i++)
          PasoPlan(
            resumen: activas[i],
            // Si el plan completo no alcanza, las fechas parciales no son
            // de fiar: no se muestran.
            meses: mesesTotales == null ? null : mesFin[i],
            fecha: mesesTotales == null ? null : fechaDe(mesFin[i]),
          ),
      ],
    );
  }
}
