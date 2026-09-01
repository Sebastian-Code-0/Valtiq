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

abstract class InteresCalculator {
  static const double _diasPorMes = 30;

  /// Devuelve la fecha de aniversario aplicando convención bancaria:
  /// si el día no existe en el mes destino, usa el último día de ese mes.
  static DateTime _aniversario(int anio, int mes, int dia) {
    // DateTime normaliza meses fuera de rango (13 → enero siguiente),
    // así que podemos calcular el último día del mes destino así:
    final ultimoDia = DateTime(anio, mes + 1, 0).day;
    final diaReal = dia > ultimoDia ? ultimoDia : dia;
    return DateTime(anio, mes, diaReal);
  }

  // fechaPrestamo/fechaLimite/etc. son fechas de negocio guardadas como
  // medianoche UTC (ver lib/utils/fecha_civil.dart); drift las reconstruye
  // con isUtc == false aunque representen ese instante UTC, así que leer
  // .year/.month/.day directo puede dar el día equivocado según el huso del
  // dispositivo. .toUtc() antes de extraer los componentes es lo que
  // garantiza el día civil correcto sin importar el huso horario actual.
  static DateTime _diaCivil(DateTime d) {
    final u = d.toUtc();
    return DateTime(u.year, u.month, u.day);
  }

  static double _mesesTranscurridos(DateTime inicio, DateTime fin) {
    final inicioNorm = _diaCivil(inicio);
    final finNorm = _diaCivil(fin);
    if (!finNorm.isAfter(inicioNorm)) return 0;

    int mesesCompletos = 0;
    while (true) {
      final siguiente = _aniversario(
        inicioNorm.year,
        inicioNorm.month + mesesCompletos + 1,
        inicioNorm.day,
      );
      if (siguiente.isAfter(finNorm)) break;
      mesesCompletos++;
    }

    final ultimoCumplimiento = _aniversario(
      inicioNorm.year,
      inicioNorm.month + mesesCompletos,
      inicioNorm.day,
    );
    final diasDiferencia = finNorm.difference(ultimoCumplimiento).inDays;
    int diasParciales = diasDiferencia;

    if (diasParciales >= _diasPorMes) {
      mesesCompletos += 1;
      diasParciales -= _diasPorMes.toInt();
    }

    return mesesCompletos + diasParciales / _diasPorMes;
  }

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
    final tasaMensual = tipoInteres == 'anual' ? tasaInteres / 12 : tasaInteres;
    return (monto * (tasaMensual / 100) * meses).round();
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
    final tasaMensual = tipoInteres == 'anual'
        ? tasaInteres / 12 / 100
        : tasaInteres / 100;
    final factor = math.pow(1 + tasaMensual, meses).toDouble();
    return (monto * (factor - 1)).round();
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
      return _resumenSaldoInsoluto(
        montoPrestado: montoPrestado,
        tasaInteres: tasaInteres,
        tipoInteres: tipoInteres,
        modalidadCalculo: modalidadCalculo,
        fechaPrestamo: fechaPrestamo,
        abonos: abonos,
        fechaFin: fechaFin,
      );
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
    final totalConInteres = montoPrestado + interes;
    final saldo = totalConInteres - totalAbonado;
    return {
      'montoPrestado': montoPrestado,
      'interesAcumulado': interes,
      'totalConInteres': totalConInteres,
      'totalAbonado': totalAbonado,
      'saldoPendiente': saldo < 0 ? 0 : saldo,
      'gananciaInteres': interes,
    };
  }

  static Map<String, int> _resumenSaldoInsoluto({
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

    int interesPeriodo(DateTime desde, DateTime hasta) {
      if (saldoCapital <= 0) return 0;
      return modalidadCalculo == 'compuesto'
          ? calcularInteresCompuesto(
              monto: saldoCapital,
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

    for (final abono in ordenados) {
      // Un abono fechado después del corte pedido (fechaFin) no pudo haber
      // ocurrido todavía desde la perspectiva de ese corte — se ignora, no
      // se proyecta hacia el futuro.
      if (abono.fecha.isAfter(fin)) continue;

      final causado = interesPeriodo(corte, abono.fecha);
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
      corte = abono.fecha;
    }

    interesTotalCausado += interesPeriodo(corte, fin);
    interesPendiente += interesPeriodo(corte, fin);

    // Un abono con fecha posterior a `fin` ya se ignoró arriba (no reduce
    // capital ni interés desde la perspectiva de este corte) — por
    // consistencia, tampoco debe contarse aquí como "abonado", o
    // totalConInteres - totalAbonado dejaría de coincidir con saldoPendiente.
    final totalAbonadoReal = ordenados
        .where((a) => !a.fecha.isAfter(fin))
        .fold<int>(0, (s, a) => s + a.monto);
    final saldoPendiente = saldoCapital + interesPendiente;

    return {
      'montoPrestado': montoPrestado,
      'interesAcumulado': interesTotalCausado,
      'totalConInteres': montoPrestado + interesTotalCausado,
      'totalAbonado': totalAbonadoReal,
      'saldoPendiente': saldoPendiente < 0 ? 0 : saldoPendiente,
      'gananciaInteres': interesTotalCausado,
    };
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
    if (tasaPeriodica <= 0) return (capital / numeroCuotas).round();
    final factor = math.pow(1 + tasaPeriodica, numeroCuotas).toDouble();
    final cuota = capital * (tasaPeriodica * factor) / (factor - 1);
    return cuota.round();
  }

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
