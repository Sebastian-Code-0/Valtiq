import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../db/database.dart';
import '../utils/date_format.dart';
import '../utils/format.dart';
import 'dashboard_service.dart';

/// Qué muestra un widget de resumen (deudas o préstamos).
enum TipoWidgetResumen {
  deudas(
    clave: 'deudas',
    proveedor: 'com.valtiq.valtiq.DeudasWidget',
    singular: 'deuda activa',
    plural: 'deudas activas',
    vacio: 'No tienes deudas activas',
  ),
  prestamos(
    clave: 'prestamos',
    proveedor: 'com.valtiq.valtiq.PrestamosWidget',
    singular: 'persona te debe',
    plural: 'personas te deben',
    vacio: 'Nadie te debe por ahora',
  );

  const TipoWidgetResumen({
    required this.clave,
    required this.proveedor,
    required this.singular,
    required this.plural,
    required this.vacio,
  });

  /// Prefijo de los datos guardados para el widget (los lee el código de
  /// Android en `android/app/src/main/kotlin/.../ResumenWidgets.kt`).
  final String clave;

  /// Clase de Android del widget.
  final String proveedor;
  final String singular;
  final String plural;
  final String vacio;
}

/// Cuántos renglones (nombre y saldo) muestra un widget de resumen.
const filasWidgetResumen = 3;

/// Los textos que se le mandan a un widget de resumen. Separado para poder
/// probarlo sin Android: total, cuántos, los [filasWidgetResumen] de mayor
/// saldo y la fecha de actualización (el interés cambia cada día y el
/// widget solo se actualiza cuando se abre Valtiq).
Map<String, String> contenidoWidgetResumen(
  TipoWidgetResumen tipo,
  List<SaldoActivo> saldos,
  DateTime ahora,
) {
  final lista = [...saldos]..sort((a, b) => b.saldo.compareTo(a.saldo));
  final total = lista.fold<int>(0, (t, s) => t + s.saldo);
  final n = lista.length;
  final k = tipo.clave;
  return {
    '${k}_total': formatCOP(total),
    '${k}_cantidad': n == 0
        ? tipo.vacio
        : '$n ${n == 1 ? tipo.singular : tipo.plural}',
    for (var i = 0; i < filasWidgetResumen; i++) ...{
      '${k}_nombre_$i': i < n ? lista[i].nombre : '',
      '${k}_monto_$i': i < n ? formatCOP(lista[i].saldo) : '',
    },
    '${k}_mas': n > filasWidgetResumen ? '+ ${n - filasWidgetResumen} más' : '',
    '${k}_actualizado': 'Actualizado ${formatDiaMesCorto(ahora)}',
  };
}

/// Mantiene al día los widgets de la pantalla de inicio de Android con lo
/// que hay en la base, mientras Valtiq está abierta.
abstract final class WidgetsService {
  /// Solo Android tiene widgets (y no en las pruebas).
  static bool get soportado =>
      !kIsWeb &&
      Platform.isAndroid &&
      !Platform.environment.containsKey('FLUTTER_TEST');

  static final _suscripciones = <StreamSubscription<Object?>>[];

  static void iniciar(AppDatabase db) {
    if (!soportado) return;
    for (final s in _suscripciones) {
      unawaited(s.cancel());
    }
    _suscripciones
      ..clear()
      ..add(
        DashboardService.watchSaldosDeudasActivas(
          db,
        ).listen((l) => _publicar(TipoWidgetResumen.deudas, l)),
      )
      ..add(
        DashboardService.watchSaldosPrestamosActivos(
          db,
        ).listen((l) => _publicar(TipoWidgetResumen.prestamos, l)),
      );
  }

  static Future<void> _publicar(
    TipoWidgetResumen tipo,
    List<SaldoActivo> saldos,
  ) async {
    try {
      final datos = contenidoWidgetResumen(tipo, saldos, DateTime.now());
      for (final e in datos.entries) {
        await HomeWidget.saveWidgetData<String>(e.key, e.value);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: tipo.proveedor);
    } catch (e) {
      // Sin widgets puestos o en un Android raro: no es un error para el
      // usuario.
      debugPrint('WidgetsService: no se pudo actualizar ${tipo.clave}: $e');
    }
  }

  /// La sección que pidió abrir un widget al tocarlo ('deudas' o
  /// 'prestamos'), o `null` si la app no se abrió desde un widget.
  static String? seccionDeUri(Uri? uri) {
    if (uri == null || uri.scheme != 'valtiq') return null;
    final seccion = uri.host;
    return const {'deudas', 'prestamos'}.contains(seccion) ? seccion : null;
  }
}
