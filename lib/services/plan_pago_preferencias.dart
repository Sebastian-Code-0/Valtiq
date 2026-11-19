import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import 'deudas_calculos.dart';
import 'interes_calculator.dart';

/// Lo que el usuario eligió en el Plan de pago: la estrategia (`null` =
/// "Automática", Valtiq usa la recomendada) y el extra al mes. Se guarda en
/// las preferencias del dispositivo y viaja en el respaldo.
class PreferenciasPlan {
  const PreferenciasPlan({required this.estrategia, required this.extra});

  static const claveEstrategia = 'valtiq_plan_estrategia';
  static const claveExtra = 'valtiq_plan_extra';

  /// Valor guardado cuando el usuario deja que Valtiq elija.
  static const automatica = 'automatica';

  final EstrategiaPago? estrategia;
  final int extra;

  /// Sin nada guardado (o con un valor desconocido) es "Automática".
  static EstrategiaPago? estrategiaDesdeClave(String? clave) {
    for (final e in EstrategiaPago.values) {
      if (e.clave == clave) return e;
    }
    return null;
  }

  static Future<PreferenciasPlan> leer() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferenciasPlan(
      estrategia: estrategiaDesdeClave(prefs.getString(claveEstrategia)),
      extra: prefs.getInt(claveExtra) ?? 0,
    );
  }

  static Future<void> guardarEstrategia(EstrategiaPago? e) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(claveEstrategia, e?.clave ?? automatica);
  }

  static Future<void> guardarExtra(int extra) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(claveExtra, extra < 0 ? 0 : extra);
  }

  /// Para el respaldo.
  Map<String, dynamic> toJson() => {
    'estrategia': estrategia?.clave ?? automatica,
    'extra': extra,
  };

  /// Restaura lo que traiga un respaldo; lo que falte o no sea válido se
  /// deja como está.
  static Future<void> restaurar(Object? json) async {
    if (json is! Map) return;
    final prefs = await SharedPreferences.getInstance();
    final estrategia = json['estrategia'];
    if (estrategia is String) {
      await prefs.setString(
        claveEstrategia,
        estrategiaDesdeClave(estrategia)?.clave ?? automatica,
      );
    }
    final extra = json['extra'];
    if (extra is num && extra >= 0) {
      await prefs.setInt(claveExtra, extra.round());
    }
  }

  /// Lo que el plan dice pagarle a la deuda [deudaId] este mes (mínimo +
  /// extra, descontando lo ya pagado este mes), con lo que el usuario
  /// eligió en el Plan de pago. `null` si no es una deuda activa o si este
  /// mes ya no le toca nada.
  ///
  /// Nunca falla: si algo sale mal devuelve `null` (es una ayuda; no debe
  /// impedir registrar un pago).
  static Future<int?> pagoDelPlan(AppDatabase db, int deudaId) async {
    try {
      return await _pagoDelPlan(db, deudaId);
    } catch (_) {
      return null;
    }
  }

  static Future<int?> _pagoDelPlan(AppDatabase db, int deudaId) async {
    final hoy = DateTime.now();
    final deudas = await db.deudasDao.getDeudasActivas();
    if (!deudas.any((d) => d.id == deudaId)) return null;
    final resumenes = [
      for (final d in deudas)
        ResumenDeuda.calcular(d, [
          for (final p in await db.pagosDeudaDao.getPagosDeDeuda(d.id))
            AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
        ], hoy: hoy),
    ];
    final prefs = await leer();
    final plan = PlanPago.elegir(
      deudas: resumenes,
      elegida: prefs.estrategia,
      extraMensual: prefs.extra,
      hoy: hoy,
    ).plan;
    for (final p in plan.orden) {
      if (p.resumen.deuda.id == deudaId) {
        return p.pagoEsteMes > 0 ? p.pagoEsteMes : null;
      }
    }
    return null;
  }
}
