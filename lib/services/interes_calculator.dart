import 'dart:math' as math;

import '../utils/fecha_civil.dart';

/// Un abono/pago puntual, tal como lo ve el motor de interés: solo fecha y
/// monto. Deliberadamente no usa las clases generadas por drift
/// (PagosDeudaData/PagosRecibido) para que este archivo no dependa de la
/// capa de base de datos — quien llame convierte su lista de pagos a esto.
class AbonoInteres {
  const AbonoInteres({required this.fecha, required this.monto});
  final DateTime fecha;
  final int monto;
}

/// Un tramo continuo del cálculo de interés: un período en el que el
/// interés corrió sobre un [capitalBase] fijo a la tasa mensual dada. En
/// modalidad `saldo_original` siempre hay un único tramo (todo el préstamo
/// corre sobre el mismo capital). En `saldo_insoluto` hay un tramo por cada
/// corte entre abonos, porque el capital baja con cada uno. Pensado para
/// que la UI le muestre al usuario el desglose real detrás del número final
/// ("¿Cómo se calculó?"), no solo el total.
class TramoInteres {
  const TramoInteres({
    required this.fechaInicio,
    required this.fechaFin,
    required this.capitalBase,
    required this.mesesCompletos,
    required this.diasParciales,
    required this.mesesTotal,
    required this.tasaMensualPct,
    required this.interes,
  });

  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int capitalBase;
  final int mesesCompletos;
  final int diasParciales;
  final double mesesTotal;
  final double tasaMensualPct;
  final int interes;
}

abstract class InteresCalculator {
  /// Convención de días por mes usada para prorratear el período parcial
  /// (el sobrante después de contar los meses completos por aniversario) —
  /// un mes de 30 días fijo, no los días reales del mes calendario. Pública
  /// para que la UI pueda explicarle esta convención al usuario (ver
  /// pantalla "Cómo funciona Valtiq") con el mismo número que usa el motor.
  static const int diasPorMesConvencion = 30;

  // fechaPrestamo/fechaLimite/etc. son fechas de negocio guardadas como
  // medianoche UTC (ver lib/utils/fecha_civil.dart); drift las reconstruye
  // con isUtc == false aunque representen ese instante UTC, así que leer
  // .year/.month/.day directo puede dar el día equivocado según el huso del
  // dispositivo. .toUtc() antes de extraer los componentes es lo que
  // garantiza el día civil correcto sin importar el huso horario actual.
  static DateTime _diaCivil(DateTime d) {
    final u = d.toUtc();
    return DateTime.utc(u.year, u.month, u.day);
  }

  /// El mismo día civil como fecha local, que es como lo recibe la UI en
  /// [TramoInteres].
  static DateTime _diaParaMostrar(DateTime d) {
    final c = _diaCivil(d);
    return DateTime(c.year, c.month, c.day);
  }

  /// Desglosa el tiempo entre dos fechas en meses completos (por
  /// aniversario del día de inicio) + días sobrantes, con la misma
  /// convención de [diasPorMesConvencion] que usa el resto del motor.
  /// Expuesto vía [desglosarPeriodo] para que la UI muestre exactamente el
  /// mismo desglose que produjo el número final, sin duplicar la lógica.
  static ({int mesesCompletos, int diasParciales, double mesesTotal})
  _desglosarMeses(DateTime inicio, DateTime fin) {
    final i = inicio.toUtc();
    final f = fin.toUtc();
    return _desglosarCivil(i.year, i.month, i.day, f.year, f.month, f.day);
  }

  /// [desglosarPeriodo] con días civiles sueltos. Es la única versión del
  /// cálculo: sin crear fechas, porque el plan de pago la llama miles de
  /// veces.
  static ({int mesesCompletos, int diasParciales, double mesesTotal})
  _desglosarCivil(int a0, int m0, int d0, int a1, int m1, int d1) {
    final numeroInicio = _numeroDia(a0, m0, d0);
    final numeroFin = _numeroDia(a1, m1, d1);
    if (numeroFin <= numeroInicio) {
      return (mesesCompletos: 0, diasParciales: 0, mesesTotal: 0);
    }
    final mesBase = a0 * 12 + m0 - 1;
    // El día [d0] del mes `mesBase + n`, o el último si ese mes es más corto.
    int aniversario(int n) {
      final indice = mesBase + n;
      final anio = indice ~/ 12;
      final mes = indice % 12 + 1;
      final ultimo = ultimoDiaDelMes(anio, mes);
      return _numeroDia(anio, mes, d0 > ultimo ? ultimo : d0);
    }

    // Arranca un mes antes de la diferencia de calendario, que siempre ya
    // se cumplió: así no se recorre mes por mes.
    var mesesCompletos = math.max(0, (a1 - a0) * 12 + m1 - m0 - 1);
    while (aniversario(mesesCompletos + 1) <= numeroFin) {
      mesesCompletos++;
    }
    var diasParciales = numeroFin - aniversario(mesesCompletos);

    if (diasParciales >= diasPorMesConvencion) {
      mesesCompletos += 1;
      diasParciales -= diasPorMesConvencion;
    }

    final mesesTotal = mesesCompletos + diasParciales / diasPorMesConvencion;
    return (
      mesesCompletos: mesesCompletos,
      diasParciales: diasParciales,
      mesesTotal: mesesTotal,
    );
  }

  /// Meses entre dos días civiles, igual que [desglosarPeriodo].
  static double mesesEntreCiviles(
    int a0,
    int m0,
    int d0,
    int a1,
    int m1,
    int d1,
  ) => _desglosarCivil(a0, m0, d0, a1, m1, d1).mesesTotal;

  static int ultimoDiaDelMes(int anio, int mes) {
    if (mes == 2) {
      final bisiesto = anio % 4 == 0 && (anio % 100 != 0 || anio % 400 == 0);
      return bisiesto ? 29 : 28;
    }
    return mes == 4 || mes == 6 || mes == 9 || mes == 11 ? 30 : 31;
  }

  /// Número de día del calendario civil: la resta de dos da los días entre
  /// ellos, sin depender del cambio de hora.
  static int _numeroDia(int anio, int mes, int dia) {
    final a = mes <= 2 ? anio - 1 : anio;
    final era = (a >= 0 ? a : a - 399) ~/ 400;
    final anioEra = a - era * 400;
    final diaAnio = (153 * (mes + (mes > 2 ? -3 : 9)) + 2) ~/ 5 + dia - 1;
    final diaEra = anioEra * 365 + anioEra ~/ 4 - anioEra ~/ 100 + diaAnio;
    return era * 146097 + diaEra;
  }

  static double _mesesTranscurridos(DateTime inicio, DateTime fin) =>
      _desglosarMeses(inicio, fin).mesesTotal;

  /// Versión pública de [_desglosarMeses] — para que una pantalla de
  /// detalle pueda mostrarle al usuario el desglose real (meses completos +
  /// días sobrantes) detrás del número de interés que ve.
  static ({int mesesCompletos, int diasParciales, double mesesTotal})
  desglosarPeriodo(DateTime inicio, DateTime fin) =>
      _desglosarMeses(inicio, fin);

  /// Techo de cualquier resultado en pesos. Un interés compuesto con una
  /// tasa disparatada durante muchos meses crece sin límite; pasado este
  /// valor se deja ahí en vez de convertirlo a entero, porque un `double`
  /// enorme "se aplasta" al entero más grande posible y las sumas siguientes
  /// se desbordan (totales absurdos o negativos).
  static const double techoPesos = 9e15;

  /// Redondea al peso un resultado intermedio, acotado a ±[techoPesos].
  static int aPesos(double valor) {
    if (valor.isNaN) return 0;
    return valor.clamp(-techoPesos, techoPesos).round();
  }

  static double _tasaMensualPct(double tasaInteres, String tipoInteres) =>
      tipoInteres == 'anual' ? tasaInteres / 12 : tasaInteres;

  /// El monto de entrada es un peso entero (int); el cálculo intermedio usa
  /// double porque la fórmula es continua (fracciones de mes, interés
  /// compuesto), pero el resultado monetario final se redondea una sola vez
  /// al peso más cercano antes de devolverse — nunca se acumulan doubles sin
  /// redondear entre llamadas sucesivas.
  static int calcularInteresSimple({
    required int monto,
    required double tasaInteres,
    required String tipoInteres,
    required DateTime fechaInicio,
    DateTime? fechaFin,
  }) {
    if (tipoInteres == 'ninguno' || tasaInteres == 0) return 0;
    final fin = fechaFin ?? normalizarFechaCivil(DateTime.now());
    final meses = _mesesTranscurridos(fechaInicio, fin);
    if (meses <= 0) return 0;
    final tasaMensual = _tasaMensualPct(tasaInteres, tipoInteres);
    return aPesos(monto * (tasaMensual / 100) * meses);
  }

  static int calcularInteresCompuesto({
    required int monto,
    required double tasaInteres,
    required String tipoInteres,
    required DateTime fechaInicio,
    DateTime? fechaFin,
  }) {
    if (tipoInteres == 'ninguno' || tasaInteres == 0) return 0;
    final fin = fechaFin ?? normalizarFechaCivil(DateTime.now());
    final meses = _mesesTranscurridos(fechaInicio, fin);
    if (meses <= 0) return 0;
    final tasaMensual = _tasaMensualPct(tasaInteres, tipoInteres) / 100;
    final factor = math.pow(1 + tasaMensual, meses).toDouble();
    return aPesos(monto * (factor - 1));
  }

  static int calcularDeudaTotal({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    required int totalAbonado,
    String tipoAmortizacion = 'saldo_original',
    List<AbonoInteres> abonos = const [],
    DateTime? fechaFin,
  }) {
    return resumenPrestamo(
      montoPrestado: montoPrestado,
      tasaInteres: tasaInteres,
      tipoInteres: tipoInteres,
      modalidadCalculo: modalidadCalculo,
      fechaPrestamo: fechaPrestamo,
      totalAbonado: totalAbonado,
      tipoAmortizacion: tipoAmortizacion,
      abonos: abonos,
      fechaFin: fechaFin,
    )['saldoPendiente']!;
  }

  /// `tipoAmortizacion`:
  /// - `'saldo_original'` (default, comportamiento histórico): el interés se
  ///   acumula siempre sobre `montoPrestado` completo desde `fechaPrestamo`
  ///   hasta `fechaFin`; los abonos solo se restan al final. Pensado para
  ///   deuda informal donde no hay certeza de que vaya a haber abonos
  ///   periódicos — "me debes X + interés sobre X hasta que pagues todo".
  ///   Con este modo `abonos` no se usa, solo `totalAbonado`.
  /// - `'saldo_insoluto'` (real bancario): cada abono en `abonos` se aplica
  ///   en orden cronológico, primero al interés causado desde el abono/corte
  ///   anterior y luego a capital; el interés siguiente se calcula sobre el
  ///   capital YA reducido. Así es como amortiza un crédito real. Con este
  ///   modo se ignora `totalAbonado` (se recalcula como la suma de `abonos`)
  ///   y `abonos` es la fuente de verdad.
  static Map<String, int> resumenPrestamo({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    required int totalAbonado,
    String tipoAmortizacion = 'saldo_original',
    List<AbonoInteres> abonos = const [],
    DateTime? fechaFin,
  }) {
    if (tipoAmortizacion == 'saldo_insoluto') {
      return _procesarSaldoInsoluto(
        montoPrestado: montoPrestado,
        tasaInteres: tasaInteres,
        tipoInteres: tipoInteres,
        modalidadCalculo: modalidadCalculo,
        fechaPrestamo: fechaPrestamo,
        abonos: abonos,
        fechaFin: fechaFin,
      ).resumen;
    }
    final interes = modalidadCalculo == 'compuesto'
        ? calcularInteresCompuesto(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
            fechaFin: fechaFin,
          )
        : calcularInteresSimple(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
            fechaFin: fechaFin,
          );
    // Igual que en saldo_insoluto: un abono con fecha posterior al corte
    // todavía no ha ocurrido, así que no cuenta.
    final corte = fechaFin ?? normalizarFechaCivil(DateTime.now());
    final abonadoAlCorte =
        totalAbonado -
        abonos
            .where((a) => a.fecha.isAfter(corte))
            .fold<int>(0, (s, a) => s + a.monto);
    final totalConInteres = montoPrestado + interes;
    final saldo = totalConInteres - abonadoAlCorte;
    return {
      'montoPrestado': montoPrestado,
      'interesAcumulado': interes,
      'totalConInteres': totalConInteres,
      'totalAbonado': abonadoAlCorte,
      'saldoPendiente': saldo < 0 ? 0 : saldo,
      'gananciaInteres': interes,
    };
  }

  /// Igual que [resumenPrestamo]/[desglosePrestamo] pero calcula ambos a la
  /// vez para modalidad `saldo_insoluto`, sin duplicar el recorrido
  /// abono-a-abono (que ya es delicado: interés pendiente que se arrastra
  /// entre cortes, capital que solo baja con lo que sobra tras pagar ese
  /// interés). `resumenPrestamo` usa solo `.resumen`; `desglosePrestamo`
  /// usa solo `.tramos`.
  static ({
    Map<String, int> resumen,
    List<TramoInteres> tramos,
    int interesPendiente,
  })
  _procesarSaldoInsoluto({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    required List<AbonoInteres> abonos,
    DateTime? fechaFin,
  }) {
    final fin = fechaFin ?? normalizarFechaCivil(DateTime.now());
    final ordenados = [...abonos]..sort((a, b) => a.fecha.compareTo(b.fecha));

    int saldoCapital = montoPrestado;
    int interesTotalCausado = 0;
    int interesPendiente = 0;
    DateTime corte = fechaPrestamo;
    final tramos = <TramoInteres>[];

    // En compuesto, el interés que un abono no alcanzó a cubrir sigue
    // generando interés. En simple solo lo genera el capital.
    int baseDelInteres() => modalidadCalculo == 'compuesto'
        ? saldoCapital + interesPendiente
        : saldoCapital;

    int interesPeriodo(DateTime desde, DateTime hasta) {
      if (saldoCapital <= 0) return 0;
      return modalidadCalculo == 'compuesto'
          ? calcularInteresCompuesto(
              monto: baseDelInteres(),
              tasaInteres: tasaInteres,
              tipoInteres: tipoInteres,
              fechaInicio: desde,
              fechaFin: hasta,
            )
          : calcularInteresSimple(
              monto: saldoCapital,
              tasaInteres: tasaInteres,
              tipoInteres: tipoInteres,
              fechaInicio: desde,
              fechaFin: hasta,
            );
    }

    void agregarTramo(DateTime desde, DateTime hasta, int interes) {
      if (saldoCapital <= 0) return;
      // Antes de sumarle a la base el interés de este mismo tramo.
      final baseInteres = baseDelInteres();
      final desglose = _desglosarMeses(desde, hasta);
      if (desglose.mesesTotal <= 0) return;
      tramos.add(
        TramoInteres(
          fechaInicio: _diaParaMostrar(desde),
          fechaFin: _diaParaMostrar(hasta),
          capitalBase: baseInteres,
          mesesCompletos: desglose.mesesCompletos,
          diasParciales: desglose.diasParciales,
          mesesTotal: desglose.mesesTotal,
          tasaMensualPct: _tasaMensualPct(tasaInteres, tipoInteres),
          interes: interes,
        ),
      );
    }

    for (final abono in ordenados) {
      // Un abono fechado después del corte pedido (fechaFin) no pudo haber
      // ocurrido todavía desde la perspectiva de ese corte — se ignora, no
      // se proyecta hacia el futuro.
      if (abono.fecha.isAfter(fin)) continue;

      // Un abono fechado antes del inicio cuenta como hecho el día del
      // inicio: el reloj del interés nunca retrocede.
      final fechaAbono = abono.fecha.isBefore(corte) ? corte : abono.fecha;
      final causado = interesPeriodo(corte, fechaAbono);
      agregarTramo(corte, fechaAbono, causado);
      interesTotalCausado += causado;
      interesPendiente += causado;

      var disponible = abono.monto;
      if (disponible <= interesPendiente) {
        interesPendiente -= disponible;
      } else {
        disponible -= interesPendiente;
        interesPendiente = 0;
        saldoCapital -= disponible;
        if (saldoCapital < 0) saldoCapital = 0;
      }
      corte = fechaAbono;
    }

    final causadoFinal = interesPeriodo(corte, fin);
    agregarTramo(corte, fin, causadoFinal);
    interesTotalCausado += causadoFinal;
    interesPendiente += causadoFinal;

    // Un abono con fecha posterior a `fin` ya se ignoró arriba (no reduce
    // capital ni interés desde la perspectiva de este corte) — por
    // consistencia, tampoco debe contarse aquí como "abonado", o
    // totalConInteres - totalAbonado dejaría de coincidir con saldoPendiente.
    final totalAbonadoReal = ordenados
        .where((a) => !a.fecha.isAfter(fin))
        .fold<int>(0, (s, a) => s + a.monto);
    final saldoPendiente = saldoCapital + interesPendiente;

    return (
      resumen: {
        'montoPrestado': montoPrestado,
        'interesAcumulado': interesTotalCausado,
        'totalConInteres': montoPrestado + interesTotalCausado,
        'totalAbonado': totalAbonadoReal,
        'saldoPendiente': saldoPendiente < 0 ? 0 : saldoPendiente,
        'gananciaInteres': interesTotalCausado,
      },
      tramos: tramos,
      interesPendiente: interesPendiente,
    );
  }

  /// El pago con fecha [fecha] que deja la deuda exactamente en $0 según el
  /// motor, contando TODOS sus pagos (los posteriores a esa fecha también:
  /// al pagar antes baja el interés, así que no basta con restarlos).
  static int montoParaLiquidar({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    required String tipoAmortizacion,
    required List<AbonoInteres> abonos,
    required DateTime fecha,
  }) {
    var corte = fecha;
    for (final a in abonos) {
      if (a.fecha.isAfter(corte)) corte = a.fecha;
    }
    int saldoCon(int pago) {
      final todos = [
        ...abonos,
        if (pago > 0) AbonoInteres(fecha: fecha, monto: pago),
      ];
      return resumenPrestamo(
        montoPrestado: montoPrestado,
        tasaInteres: tasaInteres,
        tipoInteres: tipoInteres,
        modalidadCalculo: modalidadCalculo,
        fechaPrestamo: fechaPrestamo,
        totalAbonado: todos.fold<int>(0, (s, a) => s + a.monto),
        tipoAmortizacion: tipoAmortizacion,
        abonos: todos,
        fechaFin: corte,
      )['saldoPendiente']!;
    }

    var alto = saldoCon(0);
    if (alto <= 0) return 0;
    var bajo = 1;
    while (bajo < alto) {
      final medio = (bajo + alto) ~/ 2;
      if (saldoCon(medio) <= 0) {
        alto = medio;
      } else {
        bajo = medio + 1;
      }
    }
    return bajo;
  }

  /// Parte de lo que se debe que es interés causado sin pagar (mismos
  /// parámetros de [resumenPrestamo]). Solo existe en `saldo_insoluto`: en
  /// `saldo_original` no hay separación entre capital e interés.
  static int interesPendienteInsoluto({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    List<AbonoInteres> abonos = const [],
    DateTime? fechaFin,
  }) => _procesarSaldoInsoluto(
    montoPrestado: montoPrestado,
    tasaInteres: tasaInteres,
    tipoInteres: tipoInteres,
    modalidadCalculo: modalidadCalculo,
    fechaPrestamo: fechaPrestamo,
    abonos: abonos,
    fechaFin: fechaFin,
  ).interesPendiente;

  /// Desglose tramo por tramo del interés acumulado, pensado para que la UI
  /// le muestre al usuario "¿Cómo se calculó?" en vez de solo el total. Ver
  /// [TramoInteres] y [resumenPrestamo] (mismos parámetros; este método usa
  /// la misma lógica pero devuelve el detalle en vez del resumen).
  static List<TramoInteres> desglosePrestamo({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    String tipoAmortizacion = 'saldo_original',
    List<AbonoInteres> abonos = const [],
    DateTime? fechaFin,
  }) {
    if (tipoInteres == 'ninguno' || tasaInteres == 0) return const [];
    if (tipoAmortizacion == 'saldo_insoluto') {
      return _procesarSaldoInsoluto(
        montoPrestado: montoPrestado,
        tasaInteres: tasaInteres,
        tipoInteres: tipoInteres,
        modalidadCalculo: modalidadCalculo,
        fechaPrestamo: fechaPrestamo,
        abonos: abonos,
        fechaFin: fechaFin,
      ).tramos;
    }

    final fin = fechaFin ?? normalizarFechaCivil(DateTime.now());
    final desglose = _desglosarMeses(fechaPrestamo, fin);
    if (montoPrestado <= 0 || desglose.mesesTotal <= 0) return const [];
    final interes = modalidadCalculo == 'compuesto'
        ? calcularInteresCompuesto(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
            fechaFin: fin,
          )
        : calcularInteresSimple(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
            fechaFin: fin,
          );
    return [
      TramoInteres(
        fechaInicio: _diaParaMostrar(fechaPrestamo),
        fechaFin: _diaParaMostrar(fin),
        capitalBase: montoPrestado,
        mesesCompletos: desglose.mesesCompletos,
        diasParciales: desglose.diasParciales,
        mesesTotal: desglose.mesesTotal,
        tasaMensualPct: _tasaMensualPct(tasaInteres, tipoInteres),
        interes: interes,
      ),
    ];
  }

  /// Cuota fija mensual bajo el sistema de amortización francés (cuota fija
  /// e igual en todo el plazo), el que usan los bancos colombianos para
  /// créditos de libre inversión, vehículo e hipotecario:
  ///
  ///   Cuota = Capital × [ i × (1 + i)^n ] / [ (1 + i)^n − 1 ]
  ///
  /// `tasaPeriodica` es la tasa efectiva del período EN FRACCIÓN, no en
  /// porcentaje (2% mensual → 0.02). `numeroCuotas` es el número de períodos
  /// (meses) del crédito. Con tasa 0 degenera correctamente en capital/n
  /// (cuotas iguales sin interés).
  static int calcularCuotaFija({
    required int capital,
    required double tasaPeriodica,
    required int numeroCuotas,
  }) {
    if (numeroCuotas <= 0 || capital <= 0) return 0;
    if (tasaPeriodica <= 0) {
      return _redondearACentena(capital / numeroCuotas);
    }
    final factor = math.pow(1 + tasaPeriodica, numeroCuotas).toDouble();
    final cuota = capital * (tasaPeriodica * factor) / (factor - 1);
    return _redondearACentena(cuota);
  }

  /// Redondea a la centena de peso más cercana (ej. 351.050 → 351.100) — una
  /// cuota "sugerida" con sueltos de $1-$99 no es realista como cuota fija
  /// pactada; el usuario prefiere un número redondo aunque implique que la
  /// última cuota del crédito real quede un poco distinta.
  static int _redondearACentena(double valor) => aPesos(valor / 100) * 100;

  /// Igual que [calcularCuotaFija] pero recibiendo la tasa con la misma
  /// convención que el resto de la app (`tasaInteres` en porcentaje,
  /// `tipoInteres` 'mensual'/'anual') en vez de una fracción mensual ya
  /// calculada.
  static int calcularCuotaFijaDesdeTasa({
    required int capital,
    required double tasaInteres,
    required String tipoInteres,
    required int numeroCuotas,
  }) {
    final tasaMensual = tipoInteres == 'anual'
        ? tasaInteres / 12 / 100
        : tasaInteres / 100;
    return calcularCuotaFija(
      capital: capital,
      tasaPeriodica: tasaMensual,
      numeroCuotas: numeroCuotas,
    );
  }
}
