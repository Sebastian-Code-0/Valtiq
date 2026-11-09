import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/backup_service.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // exportarDatos() llama a PackageInfo.fromPlatform(), que en el entorno
  // de test no tiene un plugin nativo real detrás — se simula la respuesta
  // del canal de plataforma para poder ejercer exportarDatos() de punta a
  // punta sin depender de un dispositivo.
  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    if (call.method == 'getAll') {
      return {
        'appName': 'Valtiq',
        'packageName': 'com.valtiq.valtiq',
        'version': '1.4.0',
        'buildNumber': '5',
        'installerStore': null,
      };
    }
    return null;
  });

  late AppDatabase db;
  late BackupService service;

  setUp(() {
    db = _createInMemoryDb();
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService', () {
    test('exportarDatos → importarDatos: round-trip preserva los montos', () async {
      await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Banco Test',
          montoOriginal: 500000,
          fechaPrestamo: DateTime(2026, 1, 1),
        ),
      );
      await db.ingresosDao.insertIngreso(
        IngresosCompanion.insert(
          concepto: 'Salario',
          monto: 1500000,
          fecha: DateTime(2026, 1, 1),
        ),
      );

      final backup = await service.exportarDatos();
      await service.importarDatos(backup);

      final deudas = await db.deudasDao.getAllDeudas();
      final ingresos = await db.ingresosDao.getAllIngresos();
      expect(deudas.single.montoOriginal, 500000);
      expect(ingresos.single.monto, 1500000);
    });

    test(
      'importarDatos: backup viejo (schemaVersion 9, montos double) se '
      'restaura redondeando en vez de fallar',
      () async {
        // Simula un backup exportado antes de la migración a montos enteros:
        // jsonDecode de un archivo real produce exactamente estos tipos
        // (double con parte decimal explícita, incluso para enteros como
        // 500000.0), y el fromJson generado por drift para una columna int
        // no acepta ese tipo si no se sanea antes.
        final backupViejo = {
          'version': 1,
          'schemaVersion': 9,
          'datos': {
            'deudas': [
              {
                'id': 1,
                'acreedorNombre': 'Banco Viejo',
                'montoOriginal': 1999.6,
                'tasaInteres': 2.5,
                'tipoInteres': 'mensual',
                'modalidadCalculo': 'simple',
                'fechaPrestamo': DateTime(2025, 1, 1).millisecondsSinceEpoch,
                'fechaLimite': null,
                'cuotaMensual': 250.4,
                'notas': '',
                'estado': 'activa',
                'fechaPagoReal': null,
                'creadoEn': DateTime(2025, 1, 1).millisecondsSinceEpoch,
                'actualizadoEn': DateTime(2025, 1, 1).millisecondsSinceEpoch,
              },
            ],
            'ingresos': [
              {
                'id': 1,
                'concepto': 'Salario viejo',
                'monto': 1500000.5,
                'frecuencia': 'mensual',
                'fecha': DateTime(2025, 1, 1).millisecondsSinceEpoch,
                'notas': '',
                'activo': true,
                'creadoEn': DateTime(2025, 1, 1).millisecondsSinceEpoch,
                'actualizadoEn': DateTime(2025, 1, 1).millisecondsSinceEpoch,
              },
            ],
          },
        };

        await service.importarDatos(backupViejo);

        final deudas = await db.deudasDao.getAllDeudas();
        final ingresos = await db.ingresosDao.getAllIngresos();
        expect(deudas.single.montoOriginal, 2000); // 1999.6 → redondeado
        expect(deudas.single.cuotaMensual, 250); // 250.4 → redondeado
        expect(ingresos.single.monto, 1500001); // 1500000.5 → redondeado
      },
    );
  });
}
