import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../utils/currency_input.dart';
import '../db/database.dart';
import '../utils/fecha_civil.dart';
import 'notification_service.dart';
import 'perfil_service.dart';
import 'plan_pago_preferencias.dart';

class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  /// 2 = trae `categorias` (schemaVersion 15). Los de versión 1 se siguen
  /// leyendo: sus categorías se arman con las de fábrica más las que usen
  /// sus gastos.
  static const formatoVersion = 2;

  Future<Map<String, dynamic>> exportarDatos() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final horaDiaria =
        await NotificationService.horaRecordatorioDiarioElegida();
    return {
      'version': formatoVersion,
      'schemaVersion': db.schemaVersion,
      'exportadoEn': DateTime.now().toIso8601String(),
      'appVersion': packageInfo.version,
      'datos': {
        'deudas': (await db.deudasDao.getAllDeudas())
            .map((e) => e.toJson())
            .toList(),
        'pagosDeuda': (await db.pagosDeudaDao.getAllPagos())
            .map((e) => e.toJson())
            .toList(),
        'prestamos': (await db.prestamosDao.getAllPrestamos())
            .map((e) => e.toJson())
            .toList(),
        'pagosRecibidos': (await db.prestamosDao.getAllPagosRecibidos())
            .map((e) => e.toJson())
            .toList(),
        'ingresos': (await db.ingresosDao.getAllIngresos())
            .map((e) => e.toJson())
            .toList(),
        'gastosFijos': (await db.gastosFijosDao.getAllGastosFijos())
            .map((e) => e.toJson())
            .toList(),
        'gastosVariables': (await db.gastosVariablesDao.getAllGastosVariables())
            .map((e) => e.toJson())
            .toList(),
        'recordatorios': (await db.recordatoriosDao.getAllRecordatorios())
            .map((e) => e.toJson())
            .toList(),
        'presupuestosCategorias':
            (await db.presupuestosCategoriasDao.getAllPresupuestos())
                .map((e) => e.toJson())
                .toList(),
        'categorias': (await db.categoriasDao.getCategorias())
            .map((e) => e.toJson())
            .toList(),
      },
      // Lo elegido en el Plan de pago (estrategia y extra al mes). Opcional:
      // los respaldos anteriores no lo traen.
      'planPago': (await PreferenciasPlan.leer()).toJson(),
      // Nombre, apellido y foto. Opcional: los respaldos anteriores no lo
      // traen.
      'perfil': await PerfilService.paraRespaldo(),
      // Solo la hora del recordatorio diario: si está encendido o no lo
      // decide cada dispositivo. Y solo si el usuario la eligió: la de
      // fábrica (8 p. m.) no debe pisar la que sí eligió en el otro.
      'recordatorioDiarioMinutos': ?horaDiaria,
      // ConfigSmtps se excluye a propósito — nunca debe salir en el backup.
      // Tampoco el PIN ni la biometría (viven fuera de la base de datos), ni
      // el tema, el menú u ocultar montos (son de cada dispositivo).
    };
  }

  // Backups viejos o parciales pueden no traer alguna clave: se trata como
  // lista vacía en vez de fallar.
  List<Map<String, dynamic>> _lista(Map<String, dynamic> datos, String clave) {
    final valor = datos[clave];
    if (valor is! List) return const [];
    return valor.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Backups creados antes de la migración de montos a entero (schemaVersion
  // 10) serializan el dinero como double (ej. 500000.0). jsonDecode lo
  // decodifica como double, y el fromJson generado por drift para una
  // columna int no acepta ese tipo (lanza TypeError). Redondea esas claves
  // a int antes de deserializar para que un backup viejo se pueda restaurar
  // igual que uno nuevo.
  Map<String, dynamic> _enteroEnClaves(
    Map<String, dynamic> row,
    List<String> claves,
  ) {
    final copia = Map<String, dynamic>.from(row);
    for (final clave in claves) {
      final valor = copia[clave];
      if (valor is! num) continue;
      // Un respaldo hecho antes del tope de montos puede traer un número
      // que no cabe (p. ej. el entero máximo, de un monto escrito con 19
      // ceros): se deja en el máximo permitido para que no desborde sumas.
      copia[clave] = valor.clamp(-maxMonto, maxMonto).round();
    }
    return copia;
  }

  // Backups creados antes de que existiera una columna (ej. modalidadCalculo
  // desde schemaVersion 8, tipoAmortizacion desde schemaVersion 12) no traen
  // esa clave en el JSON. El fromJson generado por drift para una columna no
  // nullable hace un cast directo y lanza TypeError con un valor null en vez
  // de aplicar el default de la columna — se completa a mano antes.
  Map<String, dynamic> _conDefaults(
    Map<String, dynamic> row,
    Map<String, dynamic> defaults,
  ) {
    final copia = Map<String, dynamic>.from(row);
    for (final entry in defaults.entries) {
      if (copia[entry.key] == null) copia[entry.key] = entry.value;
    }
    return copia;
  }

  // Respaldos de antes de schemaVersion 11 guardan las fechas de negocio
  // como el instante en que se registraron (con hora), no como medianoche
  // UTC de su día. La migración de la base de datos (`from < 11`) las pasa a
  // día civil, pero importar un respaldo así no pasa por ella. Se hace aquí
  // lo mismo: el día que el instante tiene en el huso de este dispositivo,
  // a medianoche UTC. Sin esto, un pago hecho el mismo día en que la deuda se
  // marcó pagada queda "después" del corte y deja de contar.
  Map<String, dynamic> _fechasCiviles(
    Map<String, dynamic> row,
    List<String> claves,
  ) {
    final copia = Map<String, dynamic>.from(row);
    for (final clave in claves) {
      final valor = copia[clave];
      final DateTime? instante = valor is num
          ? DateTime.fromMillisecondsSinceEpoch(valor.toInt())
          : valor is String
          ? DateTime.tryParse(valor)?.toLocal()
          : null;
      if (instante == null) continue;
      copia[clave] = normalizarFechaCivil(instante).millisecondsSinceEpoch;
    }
    return copia;
  }

  Future<void> importarDatos(Map<String, dynamic> json) async {
    // Mientras se cambian datos y preferencias, el Plan de pago no ajusta
    // nada con una mezcla de lo viejo y lo nuevo.
    PreferenciasPlan.restaurando++;
    try {
      await _importarDatos(json);
    } finally {
      PreferenciasPlan.restaurando--;
    }
  }

  Future<void> _importarDatos(Map<String, dynamic> json) async {
    // Validación mínima antes de tocar nada:
    if (json['datos'] is! Map) {
      throw const FormatException(
        'El archivo no tiene el formato esperado de backup de Valtiq.',
      );
    }
    final datos = Map<String, dynamic>.from(json['datos'] as Map);
    final esquema = json['schemaVersion'];
    final fechasConHora = esquema is num && esquema < 11;
    Map<String, dynamic> Function(Map<String, dynamic>) civiles(
      List<String> claves,
    ) =>
        (r) => fechasConHora ? _fechasCiviles(r, claves) : r;

    final deudas = _lista(datos, 'deudas')
        .map(
          (r) => _conDefaults(r, const {
            'modalidadCalculo': 'simple',
            'tipoAmortizacion': 'saldo_original',
            // Agregadas en schemaVersion 14: un respaldo anterior no las trae.
            'descripcion': '',
            'tipo': 'otro',
          }),
        )
        .map((r) => _enteroEnClaves(r, const ['montoOriginal', 'cuotaMensual']))
        .map(civiles(const ['fechaPrestamo', 'fechaLimite', 'fechaPagoReal']))
        .map(Deuda.fromJson)
        .toList();
    final pagosDeuda = _lista(datos, 'pagosDeuda')
        .map((r) => _enteroEnClaves(r, const ['montoAbonado']))
        .map(civiles(const ['fechaPago']))
        .map(PagosDeudaData.fromJson)
        .toList();
    final prestamos = _lista(datos, 'prestamos')
        .map(
          (r) => _conDefaults(r, const {
            'modalidadCalculo': 'simple',
            'tipoAmortizacion': 'saldo_original',
          }),
        )
        .map((r) => _enteroEnClaves(r, const ['montoPrestado']))
        .map(civiles(const ['fechaPrestamo', 'fechaPactadaPago']))
        .map(Prestamo.fromJson)
        .toList();
    final pagosRecibidos = _lista(datos, 'pagosRecibidos')
        .map((r) => _enteroEnClaves(r, const ['montoAbonado']))
        .map(civiles(const ['fechaPago']))
        .map(PagosRecibido.fromJson)
        .toList();
    final ingresos = _lista(datos, 'ingresos')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(civiles(const ['fecha']))
        .map(Ingreso.fromJson)
        .toList();
    final gastosFijos = _lista(datos, 'gastosFijos')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(GastosFijo.fromJson)
        .toList();
    final gastosVariables = _lista(datos, 'gastosVariables')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(civiles(const ['fecha']))
        .map(GastosVariable.fromJson)
        .toList();
    final recordatorios = _lista(
      datos,
      'recordatorios',
    ).map(civiles(const ['fechaAlerta'])).map(Recordatorio.fromJson).toList();
    final presupuestosCategorias = _lista(datos, 'presupuestosCategorias')
        .map((r) => _enteroEnClaves(r, const ['limiteMensual']))
        .map(PresupuestosCategoria.fromJson)
        .toList();

    // `null` = respaldo anterior a las categorías editables.
    final categorias = datos['categorias'] is List
        ? _lista(datos, 'categorias')
              .map(
                (r) => _conDefaults(r, const {
                  'icono': 'otros',
                  'orden': 0,
                  'color': 0xFF8B93A3,
                }),
              )
              .map(Categoria.fromJson)
              .toList()
        : null;

    await db.transaction(() async {
      // Borra primero las tablas hijas (referencian deuda/préstamo por FK),
      // luego las padres — mismo orden que ya sigue el borrado en cascada
      // de deudas/préstamos (deleteDeudaConPagos / deletePrestamoConPagos).
      await db.delete(db.pagosDeuda).go();
      await db.delete(db.pagosRecibidos).go();
      await db.delete(db.recordatorios).go();
      await db.delete(db.deudas).go();
      await db.delete(db.prestamos).go();
      await db.delete(db.ingresos).go();
      await db.delete(db.gastosFijos).go();
      await db.delete(db.gastosVariables).go();
      await db.delete(db.presupuestosCategorias).go();
      await db.delete(db.categorias).go();

      // Reinserta en el orden inverso: padres antes que hijos, para que las
      // FK de pagosDeuda/pagosRecibidos encuentren su deuda/préstamo ya
      // insertado. Los ids originales del backup se preservan (no se
      // regeneran), así las referencias entre tablas siguen siendo válidas.
      await db.batch((b) {
        b.insertAll(db.deudas, deudas);
        b.insertAll(db.prestamos, prestamos);
        b.insertAll(db.pagosDeuda, pagosDeuda);
        b.insertAll(db.pagosRecibidos, pagosRecibidos);
        b.insertAll(db.ingresos, ingresos);
        b.insertAll(db.gastosFijos, gastosFijos);
        b.insertAll(db.gastosVariables, gastosVariables);
        b.insertAll(db.recordatorios, recordatorios);
        b.insertAll(db.presupuestosCategorias, presupuestosCategorias);
        if (categorias != null) b.insertAll(db.categorias, categorias);
      });
      // Que ningún gasto quede con una categoría que no existe. Un respaldo
      // con categorías trae las que el usuario dejó (no se le devuelven las
      // de fábrica que borró); uno viejo arranca con las de fábrica.
      await db.sembrarCategorias(deFabrica: categorias == null);
    });
    // Después de los datos: si algo falla arriba, no se tocan.
    // Las preferencias del plan, el perfil y la hora del recordatorio son
    // un extra: si fallan, los datos ya quedaron importados y la
    // importación no debe verse como fallida.
    try {
      await PreferenciasPlan.restaurar(json['planPago']);
    } catch (e) {
      debugPrint('BackupService: no se pudo restaurar el plan de pago: $e');
      // Que el Plan abierto se recalcule igual con los datos nuevos.
      PreferenciasPlan.restauraciones.value++;
    }
    try {
      await PerfilService.restaurar(json['perfil']);
    } catch (_) {}
    try {
      await NotificationService.restaurarHoraRecordatorioDiario(
        db,
        json['recordatorioDiarioMinutos'],
      );
    } catch (_) {}
  }
}
