import 'package:drift/drift.dart';

import 'connection.dart' as conn;
import 'daos/config_smtp_dao.dart';
import 'daos/deudas_dao.dart';
import 'daos/gastos_fijos_dao.dart';
import 'daos/ingresos_dao.dart';
import 'daos/pagos_deuda_dao.dart';
import 'daos/prestamos_dao.dart';
import 'daos/gastos_variables_dao.dart';
import 'daos/presupuestos_categorias_dao.dart';
import 'daos/recordatorios_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Deudas,
    PagosDeuda,
    Prestamos,
    PagosRecibidos,
    Ingresos,
    GastosFijos,
    Recordatorios,
    ConfigSmtps,
    GastosVariables,
    PresupuestosCategorias,
  ],
  daos: [
    DeudasDao,
    PagosDeudaDao,
    PrestamosDao,
    IngresosDao,
    GastosFijosDao,
    RecordatoriosDao,
    ConfigSmtpDao,
    GastosVariablesDao,
    PresupuestosCategoriasDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static QueryExecutor openConnection() => conn.openValtiqConnection();

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(configSmtps).insert(
        const ConfigSmtpsCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(configSmtps);
        await into(configSmtps).insert(
          const ConfigSmtpsCompanion(id: Value(1)),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (from < 3) {
        await m.alterTable(
          TableMigration(
            configSmtps,
            columnTransformer: {
              // Este es el único lugar del proyecto con SQL en texto plano
              // dentro de una migración. El valor de abajo es estático y
              // fijo para esta migración puntual. No interpolar nunca una
              // variable externa aquí sin parametrizarla: esto no pasa por
              // el query builder de drift, así que cualquier interpolación
              // directa de un valor externo sería una inyección SQL.
              configSmtps.tieneContrasena: const CustomExpression(
                "CASE WHEN contrasena != '' THEN 1 ELSE 0 END",
              ),
            },
          ),
        );
        await m.createTable(pagosDeuda);
      }
      if (from < 4) {
        await m.addColumn(configSmtps, configSmtps.contrasenaEncriptada);
      }
      if (from < 5) {
        await m.addColumn(recordatorios, recordatorios.frecuenciaAviso);
        await m.addColumn(recordatorios, recordatorios.ultimaNotificacion);
        await m.addColumn(recordatorios, recordatorios.ultimoEnvioCorreo);
      }
      if (from < 6) {
        await m.addColumn(recordatorios, recordatorios.horaAviso);
        await m.addColumn(recordatorios, recordatorios.minutoAviso);
      }
      if (from < 7) {
        await m.createTable(gastosVariables);
      }
      if (from < 8) {
        await m.addColumn(deudas, deudas.modalidadCalculo);
      }
      if (from < 9) {
        await m.createTable(presupuestosCategorias);
        // Los @TableIndex ya cubren instalaciones nuevas (onCreate); estas dos
        // líneas son solo para bases de datos existentes que están actualizando.
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_pagos_deuda_deuda_id ON pagos_deuda (deuda_id)',
        );
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_pagos_recibidos_prestamo_id ON pagos_recibidos (prestamo_id)',
        );
      }
      if (from < 10) {
        // Todas las columnas de dinero pasan de REAL (double) a INTEGER
        // (peso colombiano entero, sin centavos) para evitar deriva de
        // precisión de punto flotante en cálculos de interés y sumas de
        // abonos. Los valores existentes se redondean al peso más cercano
        // (no se truncan). Las tasas de interés (porcentajes) no se tocan.
        await m.alterTable(
          TableMigration(
            deudas,
            columnTransformer: {
              deudas.montoOriginal: const CustomExpression(
                'CAST(ROUND(monto_original) AS INTEGER)',
              ),
              deudas.cuotaMensual: const CustomExpression(
                'CAST(ROUND(cuota_mensual) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            prestamos,
            columnTransformer: {
              prestamos.montoPrestado: const CustomExpression(
                'CAST(ROUND(monto_prestado) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            pagosRecibidos,
            columnTransformer: {
              pagosRecibidos.montoAbonado: const CustomExpression(
                'CAST(ROUND(monto_abonado) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            pagosDeuda,
            columnTransformer: {
              pagosDeuda.montoAbonado: const CustomExpression(
                'CAST(ROUND(monto_abonado) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            ingresos,
            columnTransformer: {
              ingresos.monto: const CustomExpression(
                'CAST(ROUND(monto) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            gastosFijos,
            columnTransformer: {
              gastosFijos.monto: const CustomExpression(
                'CAST(ROUND(monto) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            gastosVariables,
            columnTransformer: {
              gastosVariables.monto: const CustomExpression(
                'CAST(ROUND(monto) AS INTEGER)',
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            presupuestosCategorias,
            columnTransformer: {
              presupuestosCategorias.limiteMensual: const CustomExpression(
                'CAST(ROUND(limite_mensual) AS INTEGER)',
              ),
            },
          ),
        );
      }
      if (from < 11) {
        // Las fechas de NEGOCIO (fecha de una transacción, no un timestamp
        // de auditoría) pasan de instante crudo a fecha civil normalizada:
        // medianoche UTC del día que representan. Sin esto, si el usuario
        // viaja y cambia la zona horaria del dispositivo, una transacción
        // guardada cerca de medianoche puede "saltar" de día al mostrarse.
        //
        // El valor existente se interpreta en el huso horario ACTUAL del
        // dispositivo que corre la migración (no hay forma de saber en qué
        // huso se creó cada dato viejo, así que se usa el de ahora mismo,
        // igual que lo vería el usuario si abriera la app en este momento):
        // 'localtime' convierte el epoch guardado a la fecha civil local,
        // y strftime('%s', <fecha>) la reconvierte a epoch asumiendo UTC
        // (comportamiento por defecto de SQLite con strings de fecha sin
        // zona), dando la medianoche UTC de esa misma fecha civil.
        //
        // creadoEn/actualizadoEn (y Recordatorios.ultimaNotificacion/
        // ultimoEnvioCorreo) NO se tocan: son instantes de auditoría reales,
        // no fechas civiles — ver lib/utils/fecha_civil.dart.
        await m.alterTable(
          TableMigration(
            deudas,
            columnTransformer: {
              deudas.fechaPrestamo: const CustomExpression(
                "CAST(strftime('%s', date(fecha_prestamo, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
              deudas.fechaLimite: const CustomExpression(
                "CAST(strftime('%s', date(fecha_limite, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
              deudas.fechaPagoReal: const CustomExpression(
                "CAST(strftime('%s', date(fecha_pago_real, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            prestamos,
            columnTransformer: {
              prestamos.fechaPrestamo: const CustomExpression(
                "CAST(strftime('%s', date(fecha_prestamo, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
              prestamos.fechaPactadaPago: const CustomExpression(
                "CAST(strftime('%s', date(fecha_pactada_pago, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            pagosDeuda,
            columnTransformer: {
              pagosDeuda.fechaPago: const CustomExpression(
                "CAST(strftime('%s', date(fecha_pago, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            pagosRecibidos,
            columnTransformer: {
              pagosRecibidos.fechaPago: const CustomExpression(
                "CAST(strftime('%s', date(fecha_pago, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            ingresos,
            columnTransformer: {
              ingresos.fecha: const CustomExpression(
                "CAST(strftime('%s', date(fecha, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            gastosVariables,
            columnTransformer: {
              gastosVariables.fecha: const CustomExpression(
                "CAST(strftime('%s', date(fecha, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
        await m.alterTable(
          TableMigration(
            recordatorios,
            columnTransformer: {
              recordatorios.fechaAlerta: const CustomExpression(
                "CAST(strftime('%s', date(fecha_alerta, 'unixepoch', "
                "'localtime')) AS INTEGER)",
              ),
            },
          ),
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
