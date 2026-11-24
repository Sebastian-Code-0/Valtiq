import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../utils/fecha_civil.dart';
import 'deudas_calculos.dart';
import 'interes_calculator.dart';

/// La cuota de una deuda recién terminada, que el usuario puede decidir
/// seguir pagando a las demás (ver [PreferenciasPlan.cuotasLiberadas]).
class CuotaLiberada {
  const CuotaLiberada({
    required this.deuda,
    required this.monto,
    required this.desde,
  });

  final Deuda deuda;
  final int monto;

  /// Primer mes en que esa plata queda libre: el siguiente al último pago.
  final DateTime desde;

  /// Lo que de [monto] todavía no está libre en el mes de [hoy].
  int diferidoEn(DateTime hoy) =>
      _indiceMes(desde) > _indiceMes(hoy) ? monto : 0;
}

int _indiceMes(DateTime f) => f.year * 12 + f.month - 1;

/// Un aviso de cuota liberada ya atendido. Se identifica por la deuda (no
/// por la fecha de pago): volver a pagarla no lo repite. [monto] es lo que
/// se sumó al extra; 0 si el usuario lo descartó.
class LiberadaAtendida {
  const LiberadaAtendida({
    required this.deudaId,
    required this.monto,
    required this.desdeMes,
    this.ajustable = true,
  });

  final int deudaId;
  final int monto;

  /// Año × 12 + mes (desde 0) en que [monto] empieza a contar.
  final int desdeMes;

  /// El extra sigue siendo el que puso la app. Si el usuario escribió otro,
  /// ese es suyo y reabrir la deuda no lo toca.
  final bool ajustable;

  LiberadaAtendida sinAjuste() => LiberadaAtendida(
    deudaId: deudaId,
    monto: monto,
    desdeMes: desdeMes,
    ajustable: false,
  );

  /// Ya no suma nada al extra, pero el aviso sigue atendido.
  LiberadaAtendida sinMonto() => LiberadaAtendida(
    deudaId: deudaId,
    monto: 0,
    desdeMes: desdeMes,
    ajustable: false,
  );

  Map<String, dynamic> toJson() => {
    'deudaId': deudaId,
    'monto': monto,
    'desdeMes': desdeMes,
    'ajustable': ajustable,
  };

  static LiberadaAtendida? desdeJson(Object? json) {
    if (json is! Map) return null;
    final deudaId = json['deudaId'];
    final monto = json['monto'];
    final desdeMes = json['desdeMes'];
    if (deudaId is! int || monto is! int || monto < 0 || desdeMes is! int) {
      return null;
    }
    return LiberadaAtendida(
      deudaId: deudaId,
      monto: monto,
      desdeMes: desdeMes,
      ajustable: json['ajustable'] != false,
    );
  }
}

/// Lo que el usuario eligió en el Plan de pago: la estrategia (`null` =
/// "Automática", Valtiq usa la recomendada), el extra al mes y qué avisos
/// de cuota liberada ya atendió. Se guarda en las preferencias del
/// dispositivo y viaja en el respaldo.
class PreferenciasPlan {
  const PreferenciasPlan({
    required this.estrategia,
    required this.extra,
    this.liberadas = const [],
  });

  static const claveEstrategia = 'valtiq_plan_estrategia';
  static const claveExtra = 'valtiq_plan_extra';
  static const claveLiberadas = 'valtiq_plan_liberadas';

  /// Cambia cada vez que se restaura un respaldo: el Plan de pago, si está
  /// abierto, vuelve a leer lo guardado.
  static final ValueNotifier<int> restauraciones = ValueNotifier(0);

  /// Mayor que 0 mientras se importa un respaldo: los datos y las
  /// preferencias todavía no corresponden entre sí, así que no se ajusta
  /// nada.
  static int restaurando = 0;

  /// Valor guardado cuando el usuario deja que Valtiq elija.
  static const automatica = 'automatica';

  final EstrategiaPago? estrategia;
  final int extra;

  /// Avisos de cuota liberada ya atendidos (usados o descartados).
  final List<LiberadaAtendida> liberadas;

  /// Parte del extra que recién empieza después del mes de [hoy]: la cuota
  /// de una deuda terminada este mes ya se usó este mes, no se cuenta dos
  /// veces.
  int extraDiferido(DateTime hoy) => liberadas.fold(
    0,
    (s, l) => l.desdeMes > _indiceMes(hoy) ? s + l.monto : s,
  );

  /// Cuotas de deudas terminadas este mes o el anterior cuyo aviso sigue
  /// sin atender, de la más reciente a la más antigua. Las más viejas no se
  /// ofrecen: esa plata seguramente ya tiene otro destino.
  List<CuotaLiberada> cuotasLiberadas(
    List<ResumenDeuda> terminadas,
    DateTime hoy,
  ) {
    final atendidas = {for (final l in liberadas) l.deudaId};
    final mesActual = _indiceMes(hoy);
    final salida = <CuotaLiberada>[];
    for (final r in terminadas) {
      final real = r.deuda.fechaPagoReal;
      final cuota = r.deuda.cuotaMensual;
      if (real == null || cuota == null || cuota <= 0) continue;
      final f = fechaCivilGuardada(real);
      final mes = _indiceMes(f);
      if (mes > mesActual || mes < mesActual - 1) continue;
      if (atendidas.contains(r.deuda.id)) continue;
      salida.add(
        CuotaLiberada(
          deuda: r.deuda,
          monto: cuota,
          desde: DateTime(f.year, f.month + 1),
        ),
      );
    }
    salida.sort((a, b) {
      final porMes = b.desde.compareTo(a.desde);
      return porMes != 0 ? porMes : a.deuda.id.compareTo(b.deuda.id);
    });
    return salida;
  }

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
      liberadas: _leerLiberadas(prefs.getString(claveLiberadas)),
    );
  }

  static List<LiberadaAtendida> _leerLiberadas(String? texto) {
    if (texto == null) return const [];
    try {
      final lista = jsonDecode(texto);
      if (lista is! List) return const [];
      return lista
          .map(LiberadaAtendida.desdeJson)
          .whereType<LiberadaAtendida>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _guardarLiberadas(
    SharedPreferences prefs,
    List<LiberadaAtendida> lista,
  ) => prefs.setString(
    claveLiberadas,
    jsonEncode([for (final l in lista) l.toJson()]),
  );

  /// "Seguir pagándolos": suma la cuota al extra y deja el aviso atendido,
  /// las dos cosas juntas. Tocarlo dos veces no suma dos veces.
  static Future<PreferenciasPlan> usarLiberada(CuotaLiberada c) =>
      _atender(c, usar: true);

  /// "Ahora no": el aviso no vuelve a salir y el extra no cambia.
  static Future<PreferenciasPlan> descartarLiberada(CuotaLiberada c) =>
      _atender(c, usar: false);

  static Future<PreferenciasPlan> _atender(
    CuotaLiberada c, {
    required bool usar,
  }) async {
    final actual = await leer();
    if (actual.liberadas.any((l) => l.deudaId == c.deuda.id)) return actual;
    final prefs = await SharedPreferences.getInstance();
    await _guardarLiberadas(prefs, [
      ...actual.liberadas,
      LiberadaAtendida(
        deudaId: c.deuda.id,
        monto: usar ? c.monto : 0,
        desdeMes: _indiceMes(c.desde),
      ),
    ]);
    if (usar) await prefs.setInt(claveExtra, actual.extra + c.monto);
    return leer();
  }

  /// Si una deuda cuya cuota se sumó al extra volvió a estar activa, esa
  /// cuota ya se cobra otra vez por su lado: se le quita al extra para no
  /// contarla dos veces, salvo que el usuario haya escrito otro extra. El
  /// aviso queda atendido: sale una sola vez por deuda.
  static Future<PreferenciasPlan> reconciliar(Set<int> idsActivas) async {
    final actual = await leer();
    if (restaurando > 0) return actual;
    final reabiertas = [
      for (final l in actual.liberadas)
        if (idsActivas.contains(l.deudaId) && l.monto > 0) l,
    ];
    if (reabiertas.isEmpty) return actual;
    final prefs = await SharedPreferences.getInstance();
    final quitar = reabiertas.fold<int>(
      0,
      (s, l) => l.ajustable ? s + l.monto : s,
    );
    await _guardarLiberadas(prefs, [
      for (final l in actual.liberadas)
        idsActivas.contains(l.deudaId) ? l.sinMonto() : l,
    ]);
    if (quitar > 0) {
      final extra = actual.extra - quitar;
      await prefs.setInt(claveExtra, extra < 0 ? 0 : extra);
    }
    return leer();
  }

  static Future<void> guardarEstrategia(EstrategiaPago? e) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(claveEstrategia, e?.clave ?? automatica);
  }

  static Future<void> guardarExtra(int extra) async {
    final prefs = await SharedPreferences.getInstance();
    final valor = extra < 0 ? 0 : extra;
    // Lo que escribe el usuario manda: reabrir una deuda ya no se lo baja.
    if (prefs.getInt(claveExtra) != valor) {
      final atendidas = _leerLiberadas(prefs.getString(claveLiberadas));
      if (atendidas.any((l) => l.ajustable)) {
        await _guardarLiberadas(prefs, [
          for (final l in atendidas) l.sinAjuste(),
        ]);
      }
    }
    await prefs.setInt(claveExtra, valor);
  }

  /// Para el respaldo.
  Map<String, dynamic> toJson() => {
    'estrategia': estrategia?.clave ?? automatica,
    'extra': extra,
    if (liberadas.isNotEmpty)
      'liberadas': [for (final l in liberadas) l.toJson()],
  };

  /// Restaura lo que traiga un respaldo; lo que falte o no sea válido se
  /// deja como está. Un respaldo sin plan de pago no toca nada (tampoco los
  /// avisos atendidos: el extra sigue incluyendo esas cuotas). Uno con plan
  /// pero sin avisos, sí los limpia: su extra no las incluye.
  static Future<void> restaurar(Object? json) async {
    if (json is! Map) {
      restauraciones.value++;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final liberadas = json['liberadas'];
    if (liberadas is List) {
      await _guardarLiberadas(
        prefs,
        liberadas
            .map(LiberadaAtendida.desdeJson)
            .whereType<LiberadaAtendida>()
            .toList(),
      );
    } else {
      await prefs.remove(claveLiberadas);
    }
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
    restauraciones.value++;
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
    final prefs = await reconciliar({for (final d in deudas) d.id});
    // Lo pagado de más este mes a una deuda ya terminada cuenta como extra.
    final terminadas = <ResumenDeuda>[
      for (final d in await db.deudasDao.getDeudasPagadas())
        if (d.fechaPagoReal != null &&
            _indiceMes(fechaCivilGuardada(d.fechaPagoReal!)) == _indiceMes(hoy))
          ResumenDeuda.calcular(d, [
            for (final p in await db.pagosDeudaDao.getPagosDeDeuda(d.id))
              AbonoInteres(fecha: p.fechaPago, monto: p.montoAbonado),
          ], hoy: hoy),
    ];
    final plan = PlanPago.elegir(
      deudas: resumenes,
      elegida: prefs.estrategia,
      extraMensual: prefs.extra,
      extraDiferido: prefs.extraDiferido(hoy),
      terminadas: terminadas,
      hoy: hoy,
      conSugerencias: false,
    ).plan;
    for (final p in plan.orden) {
      if (p.resumen.deuda.id == deudaId) {
        return p.pagoEsteMes > 0 ? p.pagoEsteMes : null;
      }
    }
    return null;
  }
}
