import 'dart:math' as math;
import 'dart:typed_data';

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
/// Lo que queda debiendo una proyección por debajo de esto se da por
/// pagado. El saldo de hoy viene redondeado a pesos y el interés se suma con
/// decimales: sin este margen quedaba $1 colgando y, en una deuda sobre lo
/// prestado, ese peso cobraba un mes entero más de interés.
const double _casiCero = 1.5;

class ResumenDeuda {
  ResumenDeuda._({
    required this.deuda,
    required this.abonos,
    required this.saldo,
    required this.abonado,
    required this.mesesTranscurridos,
    required this.interesPendiente,
    required DateTime hoy,
  }) : _hoy = DateTime.utc(hoy.year, hoy.month, hoy.day);

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
      abonado: resumen['totalAbonado']!,
      interesPendiente: deuda.tipoAmortizacion == 'saldo_insoluto'
          ? InteresCalculator.interesPendienteInsoluto(
              montoPrestado: deuda.montoOriginal,
              tasaInteres: deuda.tasaInteres,
              tipoInteres: deuda.tipoInteres,
              modalidadCalculo: deuda.modalidadCalculo,
              fechaPrestamo: deuda.fechaPrestamo,
              abonos: abonos,
              fechaFin: fin,
            )
          : 0,
      hoy: hoy,
      mesesTranscurridos: InteresCalculator.desglosarPeriodo(
        deuda.fechaPrestamo,
        fin,
      ).mesesTotal,
    );
  }

  /// Meses calendario de [hoy] a [fecha] (negativo si ya pasó).
  static int _mesesHasta(DateTime fecha, DateTime hoy) =>
      (fecha.year - hoy.year) * 12 + fecha.month - hoy.month;

  /// Día civil desde el que se proyecta.
  final DateTime _hoy;

  /// Parte de [saldo] que es interés causado sin pagar (solo en
  /// `saldo_insoluto`). Cada pago la cubre primero y, en interés simple, no
  /// genera más interés.
  final int interesPendiente;

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

  /// Porcentaje pagado para mostrar: nunca dice 100 % si falta plata.
  int get porcentajePagado =>
      porcentajeSinRedondearArriba(fraccionPagada, faltaPlata: saldo > 0);

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

    // Antes de su primer mes de pago no hay nada que pagar.
    final primero = primerMesDePago(hoy);
    if (primero > 0) return enMes(hoy.year, hoy.month + primero);
    // Lo de este mes ya está pago: lo que sigue es el mes que viene.
    final cuota = deuda.cuotaMensual;
    final yaPago =
        pagadoEsteMes(hoy) > 0 &&
        (cuota == null || cuota <= 0 || pendienteEsteMes(hoy, cuota) == 0);
    if (yaPago) return enMes(hoy.year, hoy.month + 1);
    final hoyCivil = DateTime(hoy.year, hoy.month, hoy.day);
    final esteMes = enMes(hoy.year, hoy.month);
    return esteMes.isBefore(hoyCivil)
        ? enMes(hoy.year, hoy.month + 1)
        : esteMes;
  }

  /// Fecha que muestra la tarjeta junto a "Vence": el próximo pago si hay
  /// día de pago (o la fecha límite, si llega antes que ese pago); si no,
  /// la fecha límite de la deuda. `vencida` solo aplica a la fecha límite
  /// (un día de pago siempre apunta al futuro).
  ({DateTime fecha, bool vencida})? vencimiento(DateTime hoy) {
    final proximo = proximoPago(hoy);
    final limite = deuda.fechaLimite;
    final f = limite == null ? null : fechaCivilGuardada(limite);
    final limiteLocal = f == null ? null : DateTime(f.year, f.month, f.day);
    if (proximo != null) {
      final hoyCivil = DateTime(hoy.year, hoy.month, hoy.day);
      if (limiteLocal != null && limiteLocal.isBefore(hoyCivil)) {
        return (fecha: limiteLocal, vencida: true);
      }
      final antes =
          limiteLocal != null &&
          !limiteLocal.isBefore(hoyCivil) &&
          limiteLocal.isBefore(proximo);
      return (fecha: antes ? limiteLocal : proximo, vencida: false);
    }
    if (limiteLocal == null) return null;
    return (
      fecha: limiteLocal,
      vencida: limiteLocal.isBefore(DateTime(hoy.year, hoy.month, hoy.day)),
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

  /// Parte de un mes (con la convención del motor) que corre el interés
  /// antes del pago del mes [k]: en este mes (k = 0), de hoy al día de pago,
  /// si todavía falta y hay pago por hacer ([pagaEsteMes]); el mes 1 va
  /// desde ese pago (o desde hoy, si este mes no hay pago) y los demás de un
  /// día de pago al siguiente. Una deuda sin día de pago se proyecta con el
  /// día del mes en que empezó ([_diaProyectado]): así la fecha no cambia
  /// según el día en que se abra la app. Antes de empezar, nada.
  ///
  /// [pagadoHoy] (solo cuenta en el mes 1): este mes se le paga algo hoy
  /// (un extra, o una cuota atrasada). Ahí empieza el siguiente tramo de
  /// interés, igual que en el motor.
  double fraccionDelMes(
    int k, {
    bool pagaEsteMes = false,
    bool pagadoHoy = false,
  }) {
    final hoyCuenta = k == 1 && pagadoHoy;
    return _fracciones[k * 4 + (pagaEsteMes ? 1 : 0) + (hoyCuenta ? 2 : 0)] ??=
        _calcularFraccion(k, pagaEsteMes, hoyCuenta);
  }

  final _fracciones = <int, double>{};

  /// El día de pago del mes `hoy + j`, como día civil.
  ({int a, int m, int d}) _fechaPagoEn(int j) {
    final indice = _hoy.year * 12 + _hoy.month - 1 + j;
    final anio = indice ~/ 12;
    final mes = indice % 12 + 1;
    return (
      a: anio,
      m: mes,
      d: math.min(_diaProyectado, InteresCalculator.ultimoDiaDelMes(anio, mes)),
    );
  }

  static int _orden(({int a, int m, int d}) f) => f.a * 10000 + f.m * 100 + f.d;

  late final ({int a, int m, int d}) _inicioCivil = () {
    final f = fechaCivilGuardada(deuda.fechaPrestamo);
    return (a: f.year, m: f.month, d: f.day);
  }();

  /// Día del mes en que se proyectan los pagos: el día de pago o, si no
  /// tiene, el día en que empezó la deuda.
  int get _diaProyectado => deuda.diaPago ?? _inicioCivil.d;

  double _calcularFraccion(int k, bool pagaEsteMes, bool pagadoHoy) {
    final dia = _diaProyectado;
    final inicio = _inicioCivil;
    final porSaldo = deuda.tipoAmortizacion == 'saldo_insoluto';
    final ({int a, int m, int d}) desde;
    if (k == 0) {
      if (!pagaEsteMes) return 0;
      desde = (a: _hoy.year, m: _hoy.month, d: _hoy.day);
    } else if (k == 1) {
      final hoyCivil = (a: _hoy.year, m: _hoy.month, d: _hoy.day);
      final pagoEsteMes = _fechaPagoEn(0);
      desde = pagaEsteMes && _orden(pagoEsteMes) > _orden(hoyCivil)
          ? pagoEsteMes
          : hoyCivil;
    } else {
      desde = _fechaPagoEn(k - 1);
      // De un día de pago al del mes siguiente, sin meses cortos de por
      // medio, es exactamente un mes.
      if (dia <= 28 &&
          _orden(desde) >= _orden(inicio) &&
          (porSaldo || inicio.d <= dia)) {
        return 1;
      }
    }
    final hasta = _fechaPagoEn(k);
    final base = _orden(desde) < _orden(inicio) ? inicio : desde;
    if (_orden(hasta) <= _orden(base)) return 0;
    double entre(({int a, int m, int d}) x, ({int a, int m, int d}) y) =>
        InteresCalculator.mesesEntreCiviles(x.a, x.m, x.d, y.a, y.m, y.d);
    if (!porSaldo) {
      // Sobre lo prestado hay un solo tramo desde el inicio: se mide contra
      // él para no sumar días de más en los meses cortos.
      return math.max(0.0, entre(inicio, hasta) - entre(inicio, base));
    }
    if (!pagadoHoy &&
        !(k == 1 && pagaEsteMes) &&
        _orden(base) == _orden((a: _hoy.year, m: _hoy.month, d: _hoy.day))) {
      // Desde hoy, sin pagar nada hoy: el saldo ya trae el interés del
      // último pago (o del inicio) hasta hoy. Se mide todo el tramo como lo mide el motor, del
      // último pago al día de pago, y se resta lo ya contado: sumar los dos
      // pedazos por separado daba unos pesos de más o de menos según los
      // días de cada mes.
      final ancla = _ultimoPagoHastaHoy;
      return math.max(0.0, entre(ancla, hasta) - entre(ancla, base));
    }
    return entre(base, hasta);
  }

  /// El último pago hasta hoy (o el inicio, si no hay): ahí empieza el tramo
  /// de interés que va corriendo en `saldo_insoluto`.
  late final ({int a, int m, int d}) _ultimoPagoHastaHoy = () {
    var ultimo = _inicioCivil;
    for (final ab in abonos) {
      final f = fechaCivilGuardada(ab.fecha);
      final x = (a: f.year, m: f.month, d: f.day);
      if (_orden(x) > _orden(ultimo) && !f.isAfter(_hoy)) ultimo = x;
    }
    return ultimo;
  }();

  /// Meses de interés ya corridos antes del pago del mes [k].
  double _mesesAntesDe(int k, bool pagaEsteMes) {
    final lista = pagaEsteMes ? _acumuladosConPago : _acumulados;
    if (lista.isEmpty) lista.add(mesesTranscurridos);
    while (lista.length <= k) {
      final j = lista.length - 1;
      lista.add(lista.last + fraccionDelMes(j, pagaEsteMes: pagaEsteMes));
    }
    return lista[k];
  }

  final _acumulados = <double>[];
  final _acumuladosConPago = <double>[];

  /// [potencia] es la parte del compuesto que no depende del saldo, ya
  /// calculada (ver [_potenciaDelMes]).
  double _interesEn(
    double saldoActual,
    double mora,
    double f,
    double t0, [
    double? potencia,
  ]) {
    if (!tieneInteres || saldoActual <= 0 || f <= 0) return 0;
    final i = tasaMensualPct / 100;
    final compuesto = deuda.modalidadCalculo == 'compuesto';
    final num x;
    if (deuda.tipoAmortizacion == 'saldo_insoluto') {
      x = compuesto
          ? saldoActual * (potencia ?? _potencia(f, t0))
          : math.max(0.0, saldoActual - mora) * i * f;
    } else {
      x = compuesto
          ? deuda.montoOriginal * (potencia ?? _potencia(f, t0))
          : deuda.montoOriginal * i * f;
    }
    return x.isFinite
        ? math.min(x.toDouble(), InteresCalculator.techoPesos)
        : InteresCalculator.techoPesos;
  }

  double _potencia(double f, double t0) {
    final base = 1 + tasaMensualPct / 100;
    return deuda.tipoAmortizacion == 'saldo_insoluto'
        ? (math.pow(base, f) - 1).toDouble()
        : (math.pow(base, t0 + f) - math.pow(base, t0)).toDouble();
  }

  /// Lo que no cambia entre simulaciones de un mes: la simulación del plan
  /// pasa por aquí miles de veces y la potencia es lo más caro.
  ({double f, double t0, double? potencia}) _tramoDelMes(
    int k,
    bool pagaEsteMes,
    bool pagadoHoy,
  ) {
    final clave = k * 4 + (pagaEsteMes ? 1 : 0) + (pagadoHoy ? 2 : 0);
    if (clave < _tramos.length) {
      final t = _tramos[clave];
      if (t != null) return t;
    } else {
      _tramos.length = clave + 1;
    }
    final f = fraccionDelMes(k, pagaEsteMes: pagaEsteMes, pagadoHoy: pagadoHoy);
    final t0 = _mesesAntesDe(k, pagaEsteMes);
    final conPotencia =
        tieneInteres && f > 0 && deuda.modalidadCalculo == 'compuesto';
    return _tramos[clave] = (
      f: f,
      t0: t0,
      potencia: conPotencia ? _potencia(f, t0) : null,
    );
  }

  final _tramos = <({double f, double t0, double? potencia})?>[];

  /// Interés que se causa antes del pago del mes [k] (k = 1 es el próximo
  /// mes) cuando se debe [saldoActual], del cual [mora] es interés sin pagar.
  ///
  /// Respeta cómo está configurada la deuda, con la misma regla del motor:
  /// - `saldo_insoluto` simple: solo sobre el capital (sin la mora);
  /// - `saldo_insoluto` compuesto: sobre todo lo que se debe;
  /// - `saldo_original` simple: siempre sobre el monto original;
  /// - `saldo_original` compuesto: sobre el original ya capitalizado.
  double interesDelMes(
    int k,
    double saldoActual, {
    double mora = 0,
    bool pagaEsteMes = false,
    bool pagadoHoy = false,
  }) {
    final t = _tramoDelMes(k, pagaEsteMes, k == 1 && pagadoHoy);
    return _interesEn(saldoActual, mora, t.f, t.t0, t.potencia);
  }

  /// Interés de un mes completo con lo que se debe hoy.
  double get _interesMesCompleto => _interesEn(
    saldo.toDouble(),
    interesPendiente.toDouble(),
    1,
    mesesTranscurridos,
  );

  /// Interés de un mes como porcentaje de lo que se debe HOY: lo que de
  /// verdad cuesta cada peso de esta deuda. En `saldo_original` es más alto
  /// que la tasa, porque se sigue cobrando sobre todo lo prestado.
  double get costoMensualPct =>
      saldo <= 0 ? 0 : _interesMesCompleto / saldo * 100;

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

  /// El primer mes (contando desde hoy, 0 = este mes) en que toca cuota.
  ///
  /// Una deuda que ya empezó paga desde este mes. Una que empieza este mes o
  /// más adelante paga en su mes de inicio solo si su día de pago cae
  /// después del día en que empieza (empieza el 12 y paga los 30 → sí) o si
  /// su fecha límite cae en ese mismo mes (no hay otro mes para pagarla);
  /// si no, desde el mes siguiente.
  int primerMesDePago(DateTime hoy) {
    final inicio = fechaCivilGuardada(deuda.fechaPrestamo);
    final meses = _mesesHasta(inicio, hoy);
    if (meses < 0) return 0;
    final dia = _diaDePagoEn(inicio.year, inicio.month);
    if (dia != null && dia > inicio.day) return meses;
    final limite = deuda.fechaLimite;
    if (limite != null) {
      final l = fechaCivilGuardada(limite);
      final lCivil = DateTime(l.year, l.month, l.day);
      if (l.year == inicio.year &&
          l.month == inicio.month &&
          l.day >= inicio.day &&
          !lCivil.isBefore(DateTime(hoy.year, hoy.month, hoy.day))) {
        return meses;
      }
    }
    return meses + 1;
  }

  /// En el mes de [hoy] toca un pago (ver [primerMesDePago]).
  bool tienePagoEsteMes(DateTime hoy) => primerMesDePago(hoy) == 0;

  /// El último mes (contando desde hoy, 0 = este mes) en que un pago llega
  /// a tiempo para la fecha límite. Si el día de pago cae después del día
  /// límite (límite el 15, paga los 30), ese mes no alcanza y cuenta el
  /// anterior; pero si no hay un mes anterior con pago, cuenta el del
  /// límite: todavía se puede pagar, adelantándose al día de pago (ver
  /// [pagarAntesDe]). Negativo = el límite ya pasó; `null` si no hay fecha
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
    var meses = _mesesHasta(l, hoy);
    final dia = _diaDePagoEn(l.year, l.month);
    if (meses > primerMesDePago(hoy) && dia != null && dia > l.day) meses -= 1;
    return meses;
  }

  /// La fecha límite, si para cumplirla hay que pagar ANTES del día de pago
  /// de ese mes (límite el 25, paga los 30, y no queda un mes anterior).
  /// `null` si el día de pago normal llega a tiempo.
  DateTime? pagarAntesDe(DateTime hoy) {
    final meses = mesLimite(hoy);
    if (meses == null || meses < 0 || saldo <= 0) return null;
    final l = fechaCivilGuardada(deuda.fechaLimite!);
    if (_mesesHasta(l, hoy) != meses) return null;
    final dia = _diaDePagoEn(l.year, l.month);
    if (dia == null || dia <= l.day) return null;
    return DateTime(l.year, l.month, l.day);
  }

  /// El pago con fecha [fecha] que deja la deuda exactamente en cero,
  /// contando todos sus pagos (también los posteriores a esa fecha).
  int saldoAl(DateTime fecha) => InteresCalculator.montoParaLiquidar(
    montoPrestado: deuda.montoOriginal,
    tasaInteres: deuda.tasaInteres,
    tipoInteres: deuda.tipoInteres,
    modalidadCalculo: deuda.modalidadCalculo,
    fechaPrestamo: deuda.fechaPrestamo,
    tipoAmortizacion: deuda.tipoAmortizacion,
    abonos: abonos,
    fecha: normalizarFechaCivil(fecha),
  );

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

  /// Lo que falta de la cuota pactada este mes. Usa la cuota completa, no
  /// [pagoMinimo]: ese ya viene recortado al saldo, y descontarle lo pagado
  /// dejaría en cero un último pago que todavía falta.
  int pendienteCuotaEsteMes(DateTime hoy) =>
      pendienteEsteMes(hoy, deuda.cuotaMensual);

  /// Lo que falta de [pagoDelMes] este mes, SIN recortarlo al saldo de hoy:
  /// hasta el día de pago corre interés, así que un último pago puede
  /// necesitar más que el saldo de hoy. Para proyectar; quien lo usa lo
  /// recorta a lo que se deba ese día.
  int faltaDelPagoEsteMes(DateTime hoy, int? pagoDelMes) {
    if (pagoDelMes == null || pagoDelMes <= 0 || saldo <= 0) return 0;
    if (!tienePagoEsteMes(hoy)) return 0;
    return math.max(0, pagoDelMes - pagadoEsteMes(hoy));
  }

  /// Cuándo se termina de pagar esta deuda si se sigue pagando al
  /// [ritmoMensual] de hoy.
  ///
  /// El mes en curso cuenta (mes 0): si el pago de este mes todavía no se
  /// hizo, se descuenta en su día de pago, con el interés que corre hasta
  /// ese día (el causado hasta hoy ya está en el saldo). Es la misma regla
  /// de [PlanPago.simular], así que con el mismo pago las dos fechas
  /// coinciden.
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
    final falta = faltaDelPagoEsteMes(hoy, pago).toDouble();
    final pagaEsteMes = falta > 0;
    var restante = saldo.toDouble();
    var mora = interesPendiente.toDouble();
    if (pagaEsteMes) {
      // Hasta el día de pago corre interés, también si con este pago se
      // termina.
      restante += interesDelMes(0, restante, mora: mora, pagaEsteMes: true);
      final hastaElPago = restante - saldo;
      final pagoHoy = math.min(falta, restante);
      restante -= pagoHoy;
      mora = math.max(0.0, mora + hastaElPago - pagoHoy);
      if (restante < _casiCero) {
        return LiquidacionEstimada._(
          fecha: DateTime(hoy.year, hoy.month, 1),
          meses: 0,
          noBaja: false,
          ritmo: pago,
        );
      }
    }
    final primero = primerMesDePago(hoy);
    for (var k = 1; k <= mesesMaximosSimulacion; k++) {
      final interes = interesDelMes(
        k,
        restante,
        mora: mora,
        pagaEsteMes: pagaEsteMes,
      );
      restante += interes;
      mora += interes;
      if (k < primero) continue;
      final abono = math.min(pago.toDouble(), restante);
      restante -= abono;
      mora = math.max(0.0, mora - abono);
      if (restante < _casiCero) {
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
  int get interesProximoMes => InteresCalculator.aPesos(_interesMesCompleto);

  /// La cuota más baja (en múltiplos de $1.000) con la que esta deuda
  /// queda en cero a más tardar en el mes [meses] contando desde hoy
  /// (0 = este mes). Usa el mismo motor que todo lo demás, así que respeta
  /// si el interés es sobre lo que falta o sobre lo prestado al inicio.
  /// `null` si ya no se debe nada.
  int? cuotaParaTerminarEn(int meses, DateTime hoy) {
    if (saldo <= 0) return null;
    // Lo antes que puede terminar es su primer mes de pago.
    final objetivo = math.max(meses, primerMesDePago(hoy));
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

  /// La cuota más baja con la que quedan exactamente [pagos] pagos.
  ///
  /// Una sola regla: lo que falte de este mes cuenta como uno de esos pagos
  /// si se va a cobrar. Si este mes ya se abonó y la cuota no pasa de ese
  /// abono, este mes no se cobra nada más y los pagos empiezan el siguiente.
  int? _cuotaEnPagos(int pagos, DateTime hoy) {
    final primero = primerMesDePago(hoy);
    final abonadoHoy = pagadoEsteMes(hoy);
    final limite = mesLimite(hoy);
    // Con los pagos desde el mes siguiente, el último no puede pasarse de la
    // fecha límite.
    final cabe = limite == null || limite < 0 || pagos <= limite;
    if (primero == 0 && abonadoHoy > 0 && cabe) {
      final sinResto = cuotaParaTerminarEn(pagos, hoy);
      if (sinResto != null && sinResto <= abonadoHoy) return sinResto;
    }
    return cuotaParaTerminarEn(primero + pagos - 1, hoy);
  }

  /// La cuota para terminar en [pagos] pagos ("12 meses" = 12 pagos). Si la
  /// fecha límite llega antes, manda la fecha límite. `null` si ya no se
  /// debe nada.
  CuotaCalculada? cuotaParaPagos(int pagos, DateTime hoy) {
    if (saldo <= 0 || pagos <= 0) return null;
    final cuota = _cuotaEnPagos(pagos, hoy);
    if (cuota == null) return null;
    final limite = mesLimite(hoy);
    final fin = liquidacionCon(cuota, hoy).meses;
    if (limite != null &&
        limite >= primerMesDePago(hoy) &&
        fin != null &&
        fin > limite) {
      final conLimite = cuotaParaTerminarEn(limite, hoy);
      if (conLimite != null) {
        return CuotaCalculada(cuota: conLimite, porLimite: true);
      }
    }
    return CuotaCalculada(cuota: cuota, porLimite: false);
  }

  /// Las dos cuotas que la app sugiere para esta deuda:
  /// - **mínimo**: terminar en la cantidad de pagos de [plazosSugeridos]
  ///   según lo que se debe, o antes de la fecha límite si esta llega
  ///   primero;
  /// - **más rápido**: terminar en los pagos del plazo rápido (o en la mitad
  ///   de los pagos, si la fecha límite llega antes). `null` si saldría
  ///   igual que el mínimo.
  ///
  /// Una fecha límite que ya pasó no cuenta (se usan los plazos normales).
  /// `null` si no se debe nada.
  SugerenciasCuota? sugerirCuotas(DateTime hoy) {
    if (saldo <= 0) return null;
    final base = plazosSugeridos(saldo);
    final primero = primerMesDePago(hoy);
    var pagos = base.minimo;
    final limite = mesLimite(hoy);
    final porLimite =
        limite != null &&
        limite >= primero &&
        limite <= primero + base.minimo - 1;
    if (porLimite) pagos = math.max(1, limite - primero + 1);

    SugerenciaCuota sugerencia(int n) {
      final cuota = _cuotaEnPagos(n, hoy) ?? saldo;
      final l = liquidacionCon(cuota, hoy);
      final mesFin = primero + n - 1;
      return SugerenciaCuota(
        cuota: cuota,
        meses: l.meses ?? mesFin,
        fecha: l.fecha ?? DateTime(hoy.year, hoy.month + mesFin, 1),
      );
    }

    final minimo = sugerencia(pagos);
    final pagosRapido = pagos > base.rapido ? base.rapido : (pagos + 1) ~/ 2;
    final rapido = pagosRapido < pagos ? sugerencia(pagosRapido) : null;
    return SugerenciasCuota(
      minimo: minimo,
      rapido: rapido == null || rapido.cuota <= minimo.cuota ? null : rapido,
      porLimite: porLimite,
    );
  }
}

/// Resultado de la calculadora "terminar en N meses".
class CuotaCalculada {
  const CuotaCalculada({required this.cuota, required this.porLimite});

  final int cuota;

  /// La fecha límite llega antes de esos N pagos y mandó ella.
  final bool porLimite;
}

/// Plazos (en cantidad de pagos) de las cuotas que sugiere la app según lo
/// que se debe hoy (ver [ResumenDeuda.sugerirCuotas]): una deuda pequeña no se estira
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

/// De 0 a 100 para mostrar. Si [faltaPlata], nunca llega a 100 aunque el
/// redondeo lo diga.
int porcentajeSinRedondearArriba(double fraccion, {required bool faltaPlata}) {
  final p = (fraccion * 100).round();
  return faltaPlata && p >= 100 ? 99 : p;
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

  /// Porcentaje para mostrar: nunca dice 100 % si falta plata.
  int get porcentajePagado =>
      porcentajeSinRedondearArriba(fraccionPagada, faltaPlata: totalDeudas > 0);
}

// ───────────────────────── Plan de pago ─────────────────────────

enum EstrategiaPago {
  avalancha(
    'avalancha',
    'Avalancha',
    'Busca el orden con el que pagas menos intereses en total.',
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

  /// Las dos terminan, pero una cumple más fechas límite que la otra.
  bool get difierenEnFechas =>
      plan.alcanza &&
      otra.alcanza &&
      plan.fechasIncumplidas != otra.fechasIncumplidas;
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
    this.priorizadaPorLimite = false,
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

  /// El plan le adelantó plata por encima del orden de la estrategia para
  /// que llegue a su fecha límite.
  final bool priorizadaPorLimite;

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
  const SugerenciaExtra({
    required this.extra,
    required this.fechaLibre,
    this.soloDesdeEsteMes = false,
  });

  /// Extra TOTAL al mes (no lo que hay que sumar al que ya se puso).
  final int extra;
  final DateTime fechaLibre;

  /// Este extra alcanza solo si se paga también este mes: empezando el mes
  /// que viene ya no se cumple lo prometido.
  final bool soloDesdeEsteMes;
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
  PlanPago({
    required this.estrategia,
    required this.presupuestoMensual,
    required this.meses,
    required this.fechaLibre,
    required this.interesesTotales,
    required this.orden,
    required this.soloMinimos,
    SugerenciaExtra? Function()? calcularParaTerminar,
    SugerenciaExtra? Function()? calcularParaLimites,
    this.saldoPorMes = const [],
  }) : _calcularParaTerminar = calcularParaTerminar,
       _calcularParaLimites = calcularParaLimites;

  final SugerenciaExtra? Function()? _calcularParaTerminar;
  final SugerenciaExtra? Function()? _calcularParaLimites;

  /// El mismo plan con otra forma de calcular los extras sugeridos.
  PlanPago _conSugerencias({
    required SugerenciaExtra? Function()? paraTerminar,
    required SugerenciaExtra? Function()? paraLimites,
  }) => PlanPago(
    estrategia: estrategia,
    presupuestoMensual: presupuestoMensual,
    meses: meses,
    fechaLibre: fechaLibre,
    interesesTotales: interesesTotales,
    orden: orden,
    soloMinimos: soloMinimos,
    calcularParaTerminar: paraTerminar,
    calcularParaLimites: paraLimites,
    saldoPorMes: saldoPorMes,
  );

  final EstrategiaPago estrategia;

  /// Lo máximo que se paga en un mes entre todas: cuotas + extra, sin pasar
  /// de lo que realmente se debe. Cuando una deuda se termina, su cuota
  /// completa se pasa a la siguiente (por eso el total del mes no baja).
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

  /// Cuántas deudas terminan después de su fecha límite.
  int get fechasIncumplidas => orden.where((p) => p.tarde).length;

  /// Si el plan no alcanza: el extra mínimo con el que sí se termina. Se
  /// calcula la primera vez que se pide (cuando su aviso se va a mostrar).
  late final SugerenciaExtra? paraTerminar = _calcularParaTerminar?.call();

  /// Si alguna deuda queda después de su fecha límite: el extra mínimo con
  /// el que todas llegan a tiempo (con esta misma estrategia). También se
  /// calcula solo cuando se pide.
  late final SugerenciaExtra? paraLimites = _calcularParaLimites?.call();

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
  /// descuenta; una deuda paga desde su [ResumenDeuda.primerMesDePago]) y lo
  /// que falte del extra. [extraDiferido] es la parte del extra que recién
  /// empieza el mes que viene (la cuota de una deuda terminada este mes: esa
  /// plata ya se usó este mes). [terminadas] son las deudas ya pagadas: lo
  /// que se les pagó este mes por encima de su cuota ya cuenta como el extra
  /// del mes, aunque ya no estén en el plan.
  ///
  /// Cada mes siguiente: (1) a cada deuda se le suma su interés, (2) se paga
  /// la cuota de todas, (3) lo que sobra del presupuesto (el extra más las
  /// cuotas de las deudas ya terminadas) va a la primera deuda del orden
  /// elegido y, si la liquida, a la siguiente. El orden se escoge entre
  /// varios candidatos: el que termina, cumple más fechas y cobra menos.
  ///
  /// Con [conSugerencias] en `false` no se buscan los extras sugeridos (para
  /// las vistas previas de los botones).
  static PlanPago simular({
    required List<ResumenDeuda> deudas,
    required EstrategiaPago estrategia,
    required int extraMensual,
    required DateTime hoy,
    int extraDiferido = 0,
    List<ResumenDeuda> terminadas = const [],
    bool conSugerencias = true,
  }) {
    final activas = deudas.where((r) => r.saldo > 0).toList();
    // Prioridad fija desde hoy, que es como se explica cada método. Para
    // avalancha cuenta lo que cuesta de verdad cada deuda, no la tasa
    // escrita (ver [ResumenDeuda.costoMensualPct]).
    activas.sort((a, b) {
      if (estrategia == EstrategiaPago.avalancha) {
        final porCosto = b.costoMensualPct.compareTo(a.costoMensualPct);
        if (porCosto != 0) return porCosto;
        final porSaldo = a.saldo.compareTo(b.saldo);
        return porSaldo != 0 ? porSaldo : a.deuda.id.compareTo(b.deuda.id);
      }
      final porSaldo = a.saldo.compareTo(b.saldo);
      if (porSaldo != 0) return porSaldo;
      final porCosto = b.costoMensualPct.compareTo(a.costoMensualPct);
      return porCosto != 0 ? porCosto : a.deuda.id.compareTo(b.deuda.id);
    });

    final extra = math.max<int>(0, extraMensual);
    final extraYaUsado =
        extraDiferido +
        terminadas.fold<int>(0, (s, r) => s + r.pagadoDeMasEsteMes(hoy));
    final sim = _Simulacion(activas, hoy, extraYaUsado);
    final ordenes = sim.ordenesPara(estrategia);
    final elegido = sim.mejor(extra, ordenes);
    final corrida = elegido.corrida;
    final minimos = sim.correr(0, sim.base, cascada: false, detalle: false)!;

    final limites = [for (final r in activas) r.mesLimite(hoy)];
    // "Primero por su límite": en el orden normal llegaría tarde.
    final sinPriorizar = sim.correr(extra, sim.base, detalle: false)!;
    bool llegabaTarde(int i) {
      final l = limites[i];
      if (l == null || l < 0) return false;
      final fin = sinPriorizar.mesFin[i];
      return fin == null || fin > l;
    }

    final orden = [
      for (final (posicion, i) in elegido.prioridad.indexed)
        PasoPlan(
          resumen: activas[i],
          meses: corrida.mesFin[i],
          fecha: _fechaDe(hoy, corrida.mesFin[i]),
          // El pago con el que se termina va hacia arriba: redondeado al
          // peso más cercano a veces dejaba $1 por pagar.
          pagoEsteMes: _aPesos(
            corrida.pagosEsteMes[i],
            alzar: corrida.mesFin[i] == 0,
          ),
          pagoMesSiguiente: _aPesos(
            corrida.pagosMesSiguiente[i],
            alzar: corrida.mesFin[i] == 1,
          ),
          mesLimite: limites[i],
          priorizadaPorLimite:
              posicion < i && (llegabaTarde(i) || sim.urgentes.contains(i)),
        ),
    ];

    // Las búsquedas de extra solo se hacen cuando hay algo que arreglar y
    // usan los mismos órdenes que el plan: el extra que se sugiere cumple
    // al aplicarlo.
    final tope = 2 * activas.fold<int>(0, (s, r) => s + r.saldo) + 1000;
    SugerenciaExtra? sugerir(
      bool Function(_Corrida? c) sirve, {
      bool limites = false,
    }) {
      final x = _extraMinimo(
        ordenes,
        (x, o) =>
            sirve(sim.correr(x, o, exigirLimites: limites, detalle: false)),
        desde: extra,
        tope: tope,
      );
      if (x == null) return null;
      // Lo mismo que pasa al usar el extra, pero sin pagar nada de él este
      // mes: los mismos órdenes y la misma elección del mejor.
      final desdeElOtro = _Simulacion(activas, hoy, extraYaUsado + x);
      final siguiente = desdeElOtro.mejor(x, ordenes).corrida;
      return SugerenciaExtra(
        extra: x,
        fechaLibre: _fechaDe(hoy, sim.mejor(x, ordenes).corrida.meses)!,
        soloDesdeEsteMes:
            !siguiente.termina ||
            (limites &&
                !ordenes.any(
                  (o) => sirve(
                    desdeElOtro.correr(
                      x,
                      o,
                      exigirLimites: true,
                      detalle: false,
                    ),
                  ),
                )),
      );
    }

    final mesesTotales = corrida.meses;
    return PlanPago(
      estrategia: estrategia,
      presupuestoMensual: InteresCalculator.aPesos(corrida.pagoMaximoMes),
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
      calcularParaTerminar:
          !conSugerencias || activas.isEmpty || corrida.termina
          ? null
          : () => sugerir((c) => c!.termina),
      // También exige terminar todo: un extra que deja a tiempo las deudas
      // con fecha límite pero con otra que nunca baja no es una solución.
      calcularParaLimites: conSugerencias && orden.any((p) => p.tarde)
          ? () => sugerir((c) => c != null && c.termina, limites: true)
          : null,
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
    int extraDiferido = 0,
    List<ResumenDeuda> terminadas = const [],
    bool conSugerencias = true,
  }) {
    PlanPago con(EstrategiaPago e) => simular(
      deudas: deudas,
      estrategia: e,
      extraMensual: extraMensual,
      hoy: hoy,
      extraDiferido: extraDiferido,
      terminadas: terminadas,
      conSugerencias: conSugerencias,
    );
    final avalancha = con(EstrategiaPago.avalancha);
    final bola = con(EstrategiaPago.bolaDeNieve);
    final recomendada = recomendar(avalancha, bola);
    final usada = elegida ?? recomendada;
    var plan = usada == EstrategiaPago.avalancha ? avalancha : bola;
    if (elegida == null && conSugerencias) {
      // En "Automática", al poner el extra sugerido Valtiq puede pasarse a
      // la otra estrategia: se sugiere el menor extra de las dos que cumpla
      // ya en "Automática", con la fecha que de verdad sale.
      SugerenciaExtra? combinar(
        SugerenciaExtra? Function(PlanPago p) tomar,
        bool Function(PlanPago p) cumple,
      ) {
        final candidatas =
            [
                tomar(avalancha),
                tomar(bola),
              ].whereType<SugerenciaExtra>().toList()
              ..sort((a, b) => a.extra.compareTo(b.extra));
        for (final s in candidatas) {
          final resultado = elegir(
            deudas: deudas,
            elegida: null,
            extraMensual: s.extra,
            hoy: hoy,
            extraDiferido: extraDiferido,
            terminadas: terminadas,
            conSugerencias: false,
          ).plan;
          if (cumple(resultado)) {
            return SugerenciaExtra(
              extra: s.extra,
              fechaLibre: resultado.fechaLibre!,
              soloDesdeEsteMes: s.soloDesdeEsteMes,
            );
          }
        }
        return candidatas.isEmpty ? null : candidatas.first;
      }

      plan = plan._conSugerencias(
        paraTerminar: plan.alcanza
            ? null
            : () => combinar((p) => p.paraTerminar, (p) => p.alcanza),
        paraLimites: plan._calcularParaLimites == null
            ? null
            : () => combinar(
                (p) => p.paraLimites,
                (p) => p.alcanza && p.fechasIncumplidas == 0,
              ),
      );
    }
    return PlanElegido(
      plan: plan,
      otra: usada == EstrategiaPago.avalancha ? bola : avalancha,
      recomendada: recomendada,
      automatica: elegida == null,
    );
  }

  /// La estrategia que más conviene con estas deudas: la que termina (si
  /// solo una termina), la que cumple más fechas límite y, si empatan, la que
  /// cobra menos intereses. Si cuestan casi lo mismo gana bola de nieve:
  /// terminar deudas pronto anima y no cuesta más.
  static EstrategiaPago recomendar(PlanPago avalancha, PlanPago bola) {
    if (avalancha.alcanza != bola.alcanza) {
      return avalancha.alcanza ? avalancha.estrategia : bola.estrategia;
    }
    if (!avalancha.alcanza) return EstrategiaPago.avalancha;
    if (avalancha.fechasIncumplidas != bola.fechasIncumplidas) {
      return avalancha.fechasIncumplidas < bola.fechasIncumplidas
          ? EstrategiaPago.avalancha
          : EstrategiaPago.bolaDeNieve;
    }
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

  static int _aPesos(double valor, {required bool alzar}) => alzar
      ? InteresCalculator.aPesos((valor - 1e-6).ceilToDouble())
      : InteresCalculator.aPesos(valor);

  static DateTime? _fechaDe(DateTime hoy, int? meses) =>
      meses == null ? null : DateTime(hoy.year, hoy.month + meses, 1);

  /// El extra más pequeño (en múltiplos de $1.000, mayor que [desde]) con
  /// el que algún orden cumple; `null` si ni con [tope] se cumple.
  ///
  /// Con un orden fijo, lo que se cumple con cierto extra se cumple con más.
  /// Por eso a cada orden se le pregunta primero si le gana al mejor hasta
  /// ahora (una simulación) y solo si le gana se busca su mínimo por mitades.
  static int? _extraMinimo(
    List<List<int>> ordenes,
    bool Function(int extra, List<int> orden) cumple, {
    required int desde,
    required int tope,
  }) {
    const paso = 1000;
    final piso = desde ~/ paso + 1;
    var mejor = (tope + paso - 1) ~/ paso + 1;
    for (final o in ordenes) {
      var alto = mejor - 1;
      if (alto < piso) break;
      if (!cumple(alto * paso, o)) continue;
      var bajo = piso;
      while (bajo < alto) {
        final medio = (bajo + alto) ~/ 2;
        if (cumple(medio * paso, o)) {
          alto = medio;
        } else {
          bajo = medio + 1;
        }
      }
      mejor = bajo;
    }
    return mejor > (tope + paso - 1) ~/ paso ? null : mejor * paso;
  }
}

/// La simulación del plan. Cada mes paga la cuota de todas y reparte lo que
/// sobra siguiendo un orden fijo de prioridad. Para cumplir fechas límite
/// no hay un reparto especial: entre los órdenes candidatos
/// ([ordenesPara]) se usa el mejor ([mejor]). Como con un orden fijo más
/// plata nunca atrasa ninguna deuda, más extra nunca empeora el plan y el
/// extra mínimo se puede buscar por mitades.
class _Simulacion {
  _Simulacion(this.deudas, this.hoy, this.extraYaUsado)
    : n = deudas.length,
      cuotas = [
        for (final r in deudas)
          math.max(0, r.deuda.cuotaMensual ?? 0).toDouble(),
      ],
      primerPago = [for (final r in deudas) r.primerMesDePago(hoy)],
      // Puede recibir extra desde el mes en que empieza.
      desde = [
        for (final r in deudas)
          math.max(
            0,
            ResumenDeuda._mesesHasta(
              fechaCivilGuardada(r.deuda.fechaPrestamo),
              hoy,
            ),
          ),
      ],
      pendientes = [
        for (final r in deudas)
          r.faltaDelPagoEsteMes(hoy, r.deuda.cuotaMensual).toDouble(),
      ],
      limites = [for (final r in deudas) r.mesLimite(hoy)],
      pagadoDeMas = deudas.fold<int>(
        0,
        (s, r) => s + r.pagadoDeMasEsteMes(hoy),
      );

  /// Con hasta estas deudas se prueban todos los órdenes.
  static const _maxDeudasTodosLosOrdenes = 4;

  /// Presupuesto de la búsqueda de orden con muchas deudas, en simulaciones
  /// por deuda: una simulación tarda según cuántas deudas tiene, así que el
  /// tiempo máximo es el mismo con 5 que con 12.
  static const _presupuestoBusqueda = 720;

  /// Extras de referencia de esa búsqueda: lo que se debe dividido por esto
  /// (0 = sin extra).
  static const _divisoresReferencia = [0, 96, 48, 24, 12];

  static final _busquedas = Expando<_BusquedaGuardada>();

  /// Con hasta estas fechas límite se prueba sacrificar cada una.
  static const _maxLimitesSacrificables = 6;

  /// Una fecha límite a estos meses o menos ya se considera muy cerca.
  static const _mesesCerca = 3;

  final List<ResumenDeuda> deudas;
  final DateTime hoy;
  final int extraYaUsado;
  final int n;
  final List<double> cuotas;
  final List<int> primerPago;
  final List<int> desde;
  final List<double> pendientes;
  final List<int?> limites;
  final int pagadoDeMas;

  late final List<int> base = [for (var i = 0; i < n; i++) i];
  late final List<double> _saldosIniciales = [
    for (final r in deudas) r.saldo.toDouble(),
  ];
  late final List<double> _moraInicial = [
    for (final r in deudas) r.interesPendiente.toDouble(),
  ];
  late final int _ultimoInicio = [0, ...primerPago, ...desde].reduce(math.max);

  bool _vale(int? limite) => limite != null && limite >= 0;

  /// Vencidas primero (la más vieja adelante) y luego las que tienen su
  /// fecha límite a [_mesesCerca] meses o menos. Solo decide a quién va la
  /// plata que sobra: la cuota de cada deuda no cambia.
  late final List<int> urgentes =
      [
        for (final i in base)
          if (limites[i] != null && limites[i]! <= _mesesCerca) i,
      ]..sort((a, b) {
        final f = deudas[a].deuda.fechaLimite!.compareTo(
          deudas[b].deuda.fechaLimite!,
        );
        return f != 0 ? f : a.compareTo(b);
      });

  /// Los órdenes que se comparan, siempre los mismos sin importar el extra:
  /// cada candidato con las urgentes adelante y también tal cual, porque
  /// forzarlas puede costar otra fecha o no terminar ([_esMejor] decide).
  List<List<int>> ordenesPara(EstrategiaPago estrategia) {
    final candidatos = _candidatos(estrategia);
    if (urgentes.isEmpty) return candidatos;
    final vistos = <String>{};
    return [
      for (final o in [
        for (final c in candidatos) [...urgentes, ...c.where(_noUrgente)],
        ...candidatos,
      ])
        if (vistos.add(o.join(','))) o,
    ];
  }

  bool _noUrgente(int i) => !urgentes.contains(i);

  List<List<int>> _candidatos(EstrategiaPago estrategia) {
    if (n <= 1) return [base];
    final conLimite =
        [
          for (final i in base)
            if (_vale(limites[i])) i,
        ]..sort((a, b) {
          final f = limites[a]!.compareTo(limites[b]!);
          return f != 0 ? f : a.compareTo(b);
        });
    List<int> limitesPrimero(List<int> resto, [List<int>? cuales]) {
      final primero = cuales ?? conLimite;
      return [
        ...primero,
        for (final i in resto)
          if (!primero.contains(i)) i,
      ];
    }

    final salida = <List<int>>[base];
    if (estrategia == EstrategiaPago.bolaDeNieve) {
      // Sin riesgo de llegar tarde, bola de nieve es exactamente su orden.
      if (conLimite.isEmpty || correr(0, base, exigirLimites: true) != null) {
        return salida;
      }
    } else {
      final porSaldo = [...base]
        ..sort((a, b) {
          final f = deudas[a].saldo.compareTo(deudas[b].saldo);
          return f != 0 ? f : a.compareTo(b);
        });
      final porInteres = [...base]
        ..sort((a, b) {
          final f = deudas[b].interesProximoMes.compareTo(
            deudas[a].interesProximoMes,
          );
          return f != 0 ? f : a.compareTo(b);
        });
      // La que más cuota libera por cada peso que falta: al terminarla, esa
      // cuota ayuda a las demás (es lo que evita un "no terminas" falso).
      final porLiberar = [...base]
        ..sort((a, b) {
          final f = (cuotas[b] * deudas[a].saldo).compareTo(
            cuotas[a] * deudas[b].saldo,
          );
          return f != 0 ? f : a.compareTo(b);
        });
      salida
        ..add(porSaldo)
        ..add(porInteres)
        ..add(porLiberar);
      if (conLimite.isNotEmpty) salida.add(limitesPrimero(porSaldo));
      if (n <= _maxDeudasTodosLosOrdenes) salida.addAll(_permutar(base));
    }
    if (conLimite.isNotEmpty) {
      salida.add(limitesPrimero(base));
      // Una fecha imposible no debe quitarle la plata a las demás.
      if (conLimite.length >= 2 &&
          conLimite.length <= _maxLimitesSacrificables) {
        for (final j in conLimite) {
          salida.add(
            limitesPrimero(base, [
              for (final i in conLimite)
                if (i != j) i,
            ]),
          );
        }
      }
    }
    if (estrategia == EstrategiaPago.avalancha &&
        n > _maxDeudasTodosLosOrdenes) {
      // Con muchas deudas solo siguen los que ganaron en alguna referencia:
      // cada orden de más se simula en cada recálculo. Con fechas límite se
      // conservan todos los candidatos: son los que protegen esas fechas.
      return {
        for (final o in [
          if (conLimite.isEmpty) base else ...salida,
          ..._ordenesBuscados(salida),
        ])
          o.join(','): o,
      }.values.toList();
    }
    final vistos = <String>{};
    return [
      for (final o in salida)
        if (vistos.add(o.join(','))) o,
    ];
  }

  /// Con muchas deudas no se pueden probar todos los órdenes: desde el mejor
  /// candidato se prueba mover cada deuda a otra posición mientras mejore,
  /// con un máximo fijo de simulaciones.
  ///
  /// Se busca con extras de referencia que salen de lo que se debe, NUNCA con
  /// el extra del usuario: así los órdenes son los mismos para cualquier
  /// extra y poner más plata no puede empeorar el plan. El resultado se
  /// guarda porque un recálculo simula varias veces las mismas deudas.
  List<List<int>> _ordenesBuscados(List<List<int>> semillas) {
    final guardada = _busquedas[deudas.first];
    if (guardada != null && guardada.sirvePara(this)) return guardada.ordenes;
    // Una sola búsqueda por cartera: la vista previa y los botones cambian
    // solo el extra y la comparten con el plan principal.
    if (extraYaUsado != 0) {
      return _Simulacion(deudas, hoy, 0)._ordenesBuscados(semillas);
    }
    final total = deudas.fold<int>(0, (s, r) => s + r.saldo);
    // Lo que una referencia no gasta queda para las siguientes.
    var quedan = _presupuestoBusqueda ~/ n;
    final salida = <List<int>>[];
    for (final (j, divisor) in _divisoresReferencia.indexed) {
      final extra = divisor == 0 ? 0 : total ~/ divisor;
      final tope = quedan ~/ (_divisoresReferencia.length - j);
      final r = _mejorar(extra, [...semillas, ...salida], tope);
      quedan -= r.gastadas;
      salida.add(r.orden);
    }
    salida.addAll(_ordenParaTerminar([...semillas, ...salida], total));
    _busquedas[deudas.first] = _BusquedaGuardada(this, salida);
    return salida;
  }

  /// Si sin extra ningún candidato termina: el que termina con menos extra.
  /// Sin él, el plan diría "no terminas" con extras que sí alcanzan. Sale
  /// solo de las deudas, no del extra escrito, así que los órdenes siguen
  /// siendo los mismos para cualquier extra.
  List<List<int>> _ordenParaTerminar(List<List<int>> candidatos, int total) {
    bool termina(int x, List<int> o) => correr(x, o, detalle: false)!.termina;
    if (candidatos.any((o) => termina(0, o))) return const [];
    final umbral = PlanPago._extraMinimo(
      candidatos,
      termina,
      desde: 0,
      tope: 2 * total + 1000,
    );
    if (umbral == null) return const [];
    return [candidatos.firstWhere((o) => termina(umbral, o))];
  }

  /// Desde el mejor de [inicio], mueve cada deuda de lugar mientras mejore,
  /// sin pasar de [tope] simulaciones.
  ({List<int> orden, int gastadas}) _mejorar(
    int extra,
    List<List<int>> inicio,
    int tope,
  ) {
    final conLimite = limites.where(_vale).length;
    // Si ya termina y cumple todas las fechas, solo puede ganarle uno que
    // cobre menos: se deja de simular apenas cobre más.
    double? techo(_Corrida c) =>
        urgentes.isEmpty && c.termina && _limitesCumplidos(c) == conLimite
        ? c.intereses
        : null;
    var gastadas = inicio.length;
    var actual = inicio.first;
    var corrida = correr(extra, actual, detalle: false)!;
    for (final o in inicio.skip(1)) {
      final c = correr(extra, o, detalle: false)!;
      if (_esMejor(c, corrida)) {
        corrida = c;
        actual = o;
      }
    }
    var mejoro = true;
    while (mejoro && gastadas < tope) {
      mejoro = false;
      for (var de = 0; de < n && gastadas < tope; de++) {
        for (var a = 0; a < n && gastadas < tope; a++) {
          if (a == de) continue;
          final otro = [...actual];
          otro.insert(a, otro.removeAt(de));
          final c = correr(
            extra,
            otro,
            techoIntereses: techo(corrida),
            detalle: false,
          );
          gastadas++;
          if (c != null && _esMejor(c, corrida)) {
            corrida = c;
            actual = otro;
            mejoro = true;
          }
        }
      }
    }
    return (orden: actual, gastadas: gastadas);
  }

  static Iterable<List<int>> _permutar(List<int> resto) sync* {
    if (resto.length <= 1) {
      yield resto;
      return;
    }
    for (var i = 0; i < resto.length; i++) {
      final sin = [...resto]..removeAt(i);
      for (final cola in _permutar(sin)) {
        yield [resto[i], ...cola];
      }
    }
  }

  int _limitesCumplidos(_Corrida c) {
    var total = 0;
    for (var i = 0; i < n; i++) {
      final l = limites[i];
      final fin = c.mesFin[i];
      if (_vale(l) && fin != null && fin <= l!) total++;
    }
    return total;
  }

  /// Meses que la urgente [i] termina después de su fecha (0 si cumple;
  /// muchísimos si no termina).
  int _retraso(_Corrida c, int i) {
    final fin = c.mesFin[i];
    if (fin == null) return 1 << 30;
    return math.max(0, fin - math.max(0, limites[i]!));
  }

  /// `true` si [a] es mejor que [b]: primero que termine, luego más fechas
  /// límite cumplidas, luego que las urgentes se pasen menos de su fecha,
  /// luego, una por una, que terminen antes o (si el interés es casi igual)
  /// que les quede menos por pagar en su fecha, luego menos
  /// interés (o, si no termina, más deudas terminadas). En empate se queda el
  /// que ya estaba.
  bool _esMejor(_Corrida a, _Corrida b) {
    if (a.termina != b.termina) return a.termina;
    final la = _limitesCumplidos(a);
    final lb = _limitesCumplidos(b);
    if (la != lb) return la > lb;
    // Las urgentes, en su orden (la vencida más vieja primero):
    // 1) que cada una se pase menos meses de su fecha;
    // 2) una por una: que termine antes, aunque cueste más interés (lo que
    //    sobra va primero a ellas) y, si termina el mismo mes y el interés
    //    es casi igual, que le quede menos por pagar en su fecha (la
    //    vencida, al cerrar este mes). Si uno cobra claramente menos, manda
    //    el interés: acercar una deuda que igual llega tarde no vale pagar
    //    mucho más.
    for (final i in urgentes) {
      final ra = _retraso(a, i);
      final rb = _retraso(b, i);
      if (ra != rb) return ra < rb;
    }
    final mayor = math.max(a.intereses, b.intereses);
    final casiIgual =
        a.termina &&
        b.termina &&
        (a.intereses - b.intereses).abs() <= math.max(1000.0, mayor / 100);
    for (final i in urgentes) {
      final fa = a.mesFin[i];
      final fb = b.mesFin[i];
      if (fa != fb) {
        if (fa == null || fb == null) return fa != null;
        return fa < fb;
      }
      if (casiIgual) {
        final d = a.faltaEnLimite[i] - b.faltaEnLimite[i];
        if (d.abs() > 0.5) return d < 0;
      }
    }
    if (a.termina) return a.intereses < b.intereses - 0.5;
    int vivas(_Corrida c) => c.mesFin.where((m) => m == null).length;
    return vivas(a) < vivas(b);
  }

  ({_Corrida corrida, List<int> prioridad}) mejor(
    int extra,
    List<List<int>> ordenes,
  ) {
    final conLimite = limites.where(_vale).length;
    var prioridad = ordenes.first;
    var corrida = correr(extra, prioridad, detalle: false)!;
    for (final o in ordenes.skip(1)) {
      // Si ya termina y cumple todas las fechas, solo le gana uno que cobre
      // menos: se deja de simular apenas cobre más.
      final techo =
          urgentes.isEmpty &&
              corrida.termina &&
              _limitesCumplidos(corrida) == conLimite
          ? corrida.intereses
          : null;
      final c = correr(extra, o, techoIntereses: techo, detalle: false);
      if (c != null && _esMejor(c, corrida)) {
        corrida = c;
        prioridad = o;
      }
    }
    return (corrida: correr(extra, prioridad)!, prioridad: prioridad);
  }

  /// Corre el plan con [prioridad]. Con `cascada: false` cada deuda recibe
  /// solo su cuota: es "pagar solo los mínimos". Con [exigirLimites]
  /// devuelve `null` en cuanto una fecha límite no se cumple, y con
  /// [techoIntereses] en cuanto el interés pasa de ese valor. Con
  /// `detalle: false` no arma lo que solo se usa para mostrar (pagos por
  /// mes, serie de la gráfica): sirve para comparar órdenes.
  _Corrida? correr(
    int extraMensual,
    List<int> prioridad, {
    bool cascada = true,
    bool exigirLimites = false,
    double? techoIntereses,
    bool detalle = true,
  }) {
    final extra = cascada ? extraMensual.toDouble() : 0.0;
    final extraMes0 = cascada
        ? math.max(0, extraMensual - extraYaUsado - pagadoDeMas).toDouble()
        : 0.0;
    final saldos = Float64List(n);
    final mora = Float64List(n);
    for (var i = 0; i < n; i++) {
      saldos[i] = _saldosIniciales[i];
      mora[i] = _moraInicial[i];
    }
    final mesFin = List<int?>.filled(n, null);
    final faltaEnLimite = Float64List(n);
    // A quién se le paga algo en el mes 0: su siguiente tramo de interés
    // empieza ese día.
    final pagadoMes0 = List<bool>.filled(n, false);
    // A quién le llega plata este mes sin tocarle cuota, en su día de pago
    // (todavía no ha pasado): el mes 1 corre desde ese día.
    final pagoEnSuDia = List<bool>.filled(n, false);
    final pagosEsteMes = Float64List(detalle ? n : 0);
    final pagosMesSiguiente = Float64List(detalle ? n : 0);
    var intereses = 0.0;
    var pagoMaximo = 0.0;
    var vivas = n;
    double total() {
      var t = 0.0;
      for (var i = 0; i < n; i++) {
        final v = saldos[i];
        if (v > 0) t += v;
      }
      return t;
    }

    final saldoTotal = detalle ? <double>[total()] : const <double>[];
    final referencia = Float64List.fromList(saldos);
    var vivasEnReferencia = n;

    for (var k = 0; k <= mesesMaximosSimulacion; k++) {
      if (k > 0 && vivas == 0) break;
      // Interés antes del pago. Este mes, solo a la que todavía tiene un
      // pago por hacer: corre hasta su día de pago, también si con ese pago
      // se termina.
      for (var i = 0; i < n; i++) {
        if (mesFin[i] != null) continue;
        final pagaEsteMes = pendientes[i] > 0 || pagoEnSuDia[i];
        if (k == 0 && !pagaEsteMes) continue;
        final interes = deudas[i].interesDelMes(
          k,
          saldos[i],
          mora: mora[i],
          pagaEsteMes: pagaEsteMes,
          pagadoHoy: k == 1 && pagadoMes0[i],
        );
        saldos[i] += interes;
        mora[i] += interes;
        intereses += interes;
      }
      if (techoIntereses != null && intereses > techoIntereses) return null;
      final conInteres = detalle ? total() : 0.0;
      final registro = !detalle
          ? null
          : k == 0
          ? pagosEsteMes
          : k == 1
          ? pagosMesSiguiente
          : null;

      // Cuotas (las de las ya terminadas quedan disponibles)…
      var disponible = k == 0 ? extraMes0 : extra;
      for (var i = 0; i < n; i++) {
        if (k < primerPago[i]) continue;
        final cuota = k == 0 ? pendientes[i] : cuotas[i];
        disponible += cuota;
        if (mesFin[i] != null) continue;
        final pago = cuota < saldos[i] ? cuota : saldos[i];
        saldos[i] -= pago;
        final m = mora[i] - pago;
        mora[i] = m > 0 ? m : 0;
        if (registro != null) registro[i] += pago;
        if (k == 0 && pago > 0) pagadoMes0[i] = true;
        disponible -= pago;
      }
      // …y lo que sobra, por orden de prioridad.
      if (cascada) {
        for (var j = 0; j < prioridad.length; j++) {
          if (disponible <= 0.5) break;
          final i = prioridad[j];
          if (mesFin[i] != null || k < desde[i]) continue;
          if (k == 0 && !(pendientes[i] > 0) && !pagoEnSuDia[i]) {
            // Este mes no le toca cuota pero le llega plata: se le paga en
            // su día de pago, como los meses siguientes, con el interés que
            // corre hasta ese día. Si ese día ya pasó, se le paga hoy.
            final hastaSuDia = deudas[i].interesDelMes(
              0,
              saldos[i],
              mora: mora[i],
              pagaEsteMes: true,
            );
            if (deudas[i].fraccionDelMes(0, pagaEsteMes: true) > 0) {
              pagoEnSuDia[i] = true;
              saldos[i] += hastaSuDia;
              mora[i] += hastaSuDia;
              intereses += hastaSuDia;
            }
          }
          final pago = disponible < saldos[i] ? disponible : saldos[i];
          saldos[i] -= pago;
          final m = mora[i] - pago;
          mora[i] = m > 0 ? m : 0;
          if (registro != null) registro[i] += pago;
          if (k == 0 && pago > 0) pagadoMes0[i] = true;
          disponible -= pago;
        }
      }
      for (var i = 0; i < n; i++) {
        if (mesFin[i] == null && saldos[i] < _casiCero) {
          mesFin[i] = k;
          vivas--;
        }
      }
      for (final i in urgentes) {
        if (math.max(0, limites[i]!) == k && mesFin[i] == null) {
          faltaEnLimite[i] = saldos[i];
        }
      }
      if (detalle) {
        final despues = total();
        saldoTotal.add(despues);
        pagoMaximo = math.max(pagoMaximo, conInteres - despues);
      }
      if (exigirLimites) {
        for (var i = 0; i < n; i++) {
          final l = limites[i];
          if (_vale(l) && l! <= k && mesFin[i] == null) return null;
        }
      }
      // Si en un año ninguna bajó, con el mismo pago ya no van a bajar.
      if (k > _ultimoInicio && k % 12 == 0) {
        var baja = vivas < vivasEnReferencia;
        for (var i = 0; i < n && !baja; i++) {
          baja = mesFin[i] == null && saldos[i] < referencia[i] - 0.5;
        }
        if (!baja) break;
        referencia.setAll(0, saldos);
        vivasEnReferencia = vivas;
      }
    }
    return _Corrida(
      mesFin: mesFin,
      faltaEnLimite: faltaEnLimite,
      intereses: intereses,
      pagosEsteMes: pagosEsteMes,
      pagosMesSiguiente: pagosMesSiguiente,
      saldoTotal: saldoTotal,
      pagoMaximoMes: pagoMaximo,
    );
  }
}

/// Los órdenes ya buscados para exactamente estas deudas y este día.
class _BusquedaGuardada {
  _BusquedaGuardada(_Simulacion s, this.ordenes)
    : deudas = s.deudas,
      hoy = s.hoy;

  final List<ResumenDeuda> deudas;
  final DateTime hoy;
  final List<List<int>> ordenes;

  bool sirvePara(_Simulacion s) {
    if (s.hoy.year != hoy.year ||
        s.hoy.month != hoy.month ||
        s.hoy.day != hoy.day ||
        s.deudas.length != deudas.length) {
      return false;
    }
    for (var i = 0; i < deudas.length; i++) {
      if (!identical(s.deudas[i], deudas[i])) return false;
    }
    return true;
  }
}

class _Corrida {
  _Corrida({
    required this.mesFin,
    required this.faltaEnLimite,
    required this.intereses,
    required this.pagosEsteMes,
    required this.pagosMesSiguiente,
    required this.saldoTotal,
    required this.pagoMaximoMes,
  });

  /// Mes en que cada deuda queda en cero (0 = este mes); `null` = nunca.
  final List<int?> mesFin;

  /// Lo que le falta a cada deuda urgente al cerrar el mes de su fecha
  /// límite (la vencida, este mes); 0 si ya terminó o no es urgente.
  final List<double> faltaEnLimite;
  final double intereses;
  final List<double> pagosEsteMes;
  final List<double> pagosMesSiguiente;

  /// Total adeudado hoy y al cerrar cada mes simulado.
  final List<double> saldoTotal;

  /// Lo más que se paga en un mes del plan.
  final double pagoMaximoMes;

  bool get termina => mesFin.every((m) => m != null);

  /// Meses hasta terminar todas; 0 si no hay deudas; `null` si alguna no
  /// termina.
  int? get meses =>
      !termina ? null : mesFin.fold<int>(0, (s, m) => math.max(s, m!));
}
