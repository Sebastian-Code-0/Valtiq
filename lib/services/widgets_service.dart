import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../db/database.dart';
import '../utils/fecha_civil.dart';
import '../utils/format.dart';
import 'dashboard_service.dart';

/// Qué muestra un widget de resumen (deudas o préstamos): lo mismo que la
/// tarjeta de Inicio.
enum TipoWidgetResumen {
  deudas(
    clave: 'deudas',
    proveedor: 'com.valtiq.valtiq.DeudasWidget',
    nota: 'Lo que debes hoy',
    vacio: 'No tienes deudas activas',
  ),
  prestamos(
    clave: 'prestamos',
    proveedor: 'com.valtiq.valtiq.PrestamosWidget',
    nota: 'Lo que te deben hoy',
    vacio: 'Nadie te debe por ahora',
  );

  const TipoWidgetResumen({
    required this.clave,
    required this.proveedor,
    required this.nota,
    required this.vacio,
  });

  /// Prefijo de los datos guardados para el widget (los lee el código de
  /// Android en `android/app/src/main/kotlin/.../ResumenWidgets.kt`).
  final String clave;

  /// Clase de Android del widget.
  final String proveedor;
  final String nota;
  final String vacio;
}

/// Cuántos días quedan calculados para el widget. El interés cambia cada
/// día y el widget no puede calcularlo solo, así que Valtiq le deja el
/// total de hoy y de los días que siguen: mientras nadie registre un pago
/// (y eso solo se hace dentro de Valtiq, que lo recalcula), esos números
/// son los reales. Pasados estos días sin abrir Valtiq, el widget no
/// muestra montos y pide abrirla.
const diasWidgetResumen = 90;

/// `2026-11-12`: la fecha civil como la lee el widget de Android.
String _fechaWidget(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Los datos que se le dejan a un widget de resumen. Separado para poder
/// probarlo sin Android:
/// - `{clave}_desde`: el primer día calculado (hoy),
/// - `{clave}_totales`: un total por renglón, de hoy en adelante
///   ([diasWidgetResumen] renglones),
/// - `{clave}_nota`: "Lo que debes hoy", o que no hay ninguna.
Map<String, String> contenidoWidgetResumen(
  TipoWidgetResumen tipo,
  List<CuentaActiva> cuentas,
  DateTime ahora,
) {
  final hoy = normalizarFechaCivil(ahora);
  final k = tipo.clave;
  return {
    '${k}_desde': _fechaWidget(hoy),
    '${k}_totales': [
      for (var i = 0; i < diasWidgetResumen; i++)
        formatCOP(
          cuentas.fold<int>(
            0,
            (t, c) => t + c.saldoAl(hoy.add(Duration(days: i))),
          ),
        ),
    ].join('\n'),
    '${k}_nota': cuentas.isEmpty ? tipo.vacio : tipo.nota,
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
        DashboardService.watchDeudasActivas(
          db,
        ).listen((l) => _publicar(TipoWidgetResumen.deudas, l)),
      )
      ..add(
        DashboardService.watchPrestamosActivos(
          db,
        ).listen((l) => _publicar(TipoWidgetResumen.prestamos, l)),
      );
  }

  static Future<void> _publicar(
    TipoWidgetResumen tipo,
    List<CuentaActiva> cuentas,
  ) async {
    try {
      final datos = contenidoWidgetResumen(tipo, cuentas, DateTime.now());
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
