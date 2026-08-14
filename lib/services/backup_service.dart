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

  Future<void> importarDatos(Map<String, dynamic> json) async {
    // Validación mínima antes de tocar nada:
    if (json['datos'] is! Map) {
      throw const FormatException(
        'El archivo no tiene el formato esperado de backup de Valtiq.',
      );
    }
    final datos = Map<String, dynamic>.from(json['datos'] as Map);

    final deudas = _lista(datos, 'deudas').map(Deuda.fromJson).toList();
    final pagosDeuda = _lista(
      datos,
      'pagosDeuda',
    ).map(PagosDeudaData.fromJson).toList();
    final prestamos = _lista(
      datos,
      'prestamos',
    ).map(Prestamo.fromJson).toList();
    final pagosRecibidos = _lista(
      datos,
      'pagosRecibidos',
    ).map(PagosRecibido.fromJson).toList();
    final ingresos = _lista(datos, 'ingresos').map(Ingreso.fromJson).toList();
    final gastosFijos = _lista(
      datos,
      'gastosFijos',
    ).map(GastosFijo.fromJson).toList();
    final gastosVariables = _lista(
      datos,
      'gastosVariables',
    ).map(GastosVariable.fromJson).toList();
    final recordatorios = _lista(
      datos,
      'recordatorios',
    ).map(Recordatorio.fromJson).toList();

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
      });
    });
  }
}
