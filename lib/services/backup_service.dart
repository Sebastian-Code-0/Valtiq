import 'package:package_info_plus/package_info_plus.dart';

import '../db/database.dart';

class BackupService {
  BackupService(this.db);
  final AppDatabase db;

  static const formatoVersion = 1;

  Future<Map<String, dynamic>> exportarDatos() async {
    final packageInfo = await PackageInfo.fromPlatform();
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
      },
      // ConfigSmtps se excluye a propósito — nunca debe salir en el backup.
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
      if (valor is double) copia[clave] = valor.round();
    }
    return copia;
  }

  Future<void> importarDatos(Map<String, dynamic> json) async {
    // Validación mínima antes de tocar nada:
    if (json['datos'] is! Map) {
      throw const FormatException(
        'El archivo no tiene el formato esperado de backup de Valtiq.',
      );
    }
    final datos = Map<String, dynamic>.from(json['datos'] as Map);

    final deudas = _lista(datos, 'deudas')
        .map((r) => _enteroEnClaves(r, const ['montoOriginal', 'cuotaMensual']))
        .map(Deuda.fromJson)
        .toList();
    final pagosDeuda = _lista(datos, 'pagosDeuda')
        .map((r) => _enteroEnClaves(r, const ['montoAbonado']))
        .map(PagosDeudaData.fromJson)
        .toList();
    final prestamos = _lista(datos, 'prestamos')
        .map((r) => _enteroEnClaves(r, const ['montoPrestado']))
        .map(Prestamo.fromJson)
        .toList();
    final pagosRecibidos = _lista(datos, 'pagosRecibidos')
        .map((r) => _enteroEnClaves(r, const ['montoAbonado']))
        .map(PagosRecibido.fromJson)
        .toList();
    final ingresos = _lista(datos, 'ingresos')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(Ingreso.fromJson)
        .toList();
    final gastosFijos = _lista(datos, 'gastosFijos')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(GastosFijo.fromJson)
        .toList();
    final gastosVariables = _lista(datos, 'gastosVariables')
        .map((r) => _enteroEnClaves(r, const ['monto']))
        .map(GastosVariable.fromJson)
        .toList();
    final recordatorios = _lista(
      datos,
      'recordatorios',
    ).map(Recordatorio.fromJson).toList();
    final presupuestosCategorias = _lista(datos, 'presupuestosCategorias')
        .map((r) => _enteroEnClaves(r, const ['limiteMensual']))
        .map(PresupuestosCategoria.fromJson)
        .toList();

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
      });
    });
  }
}
