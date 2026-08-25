import 'dart:math' as math;

import '../utils/fecha_civil.dart';

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
  }) {
    final interes = modalidadCalculo == 'compuesto'
        ? calcularInteresCompuesto(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
          )
        : calcularInteresSimple(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
          );
    final total = montoPrestado + interes - totalAbonado;
    return total < 0 ? 0 : total;
  }

  static Map<String, int> resumenPrestamo({
    required int montoPrestado,
    required double tasaInteres,
    required String tipoInteres,
    required String modalidadCalculo,
    required DateTime fechaPrestamo,
    required int totalAbonado,
  }) {
    final interes = modalidadCalculo == 'compuesto'
        ? calcularInteresCompuesto(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
          )
        : calcularInteresSimple(
            monto: montoPrestado,
            tasaInteres: tasaInteres,
            tipoInteres: tipoInteres,
            fechaInicio: fechaPrestamo,
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
}
