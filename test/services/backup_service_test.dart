import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/services/backup_service.dart';
import 'package:valtiq/services/deudas_calculos.dart';
import 'package:valtiq/services/notification_service.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/services/plan_pago_preferencias.dart';

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
    SharedPreferences.setMockInitialValues({});
    db = _createInMemoryDb();
    service = BackupService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('BackupService', () {
    test('las categorías van en el respaldo y vuelven tal cual (con las '
        'nuevas, sin las borradas)', () async {
      final dao = db.categoriasDao;
      await dao.crear(nombre: 'Gimnasio', icono: 'gimnasio', color: 0xFF5B8DBE);
      final ropa = (await dao.getCategorias()).firstWhere(
        (c) => c.nombre == 'Ropa',
      );
      await dao.borrar(ropa, moverAOtros: false);
      await db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: 'Mensualidad',
          monto: 90000,
          categoria: 'Gimnasio',
          fecha: DateTime.utc(2026, 11, 1),
        ),
      );
      final antes = (await dao.getCategorias()).map((c) => c.nombre).toList();

      final backup = await service.exportarDatos();
      expect(backup['version'], BackupService.formatoVersion);
      await service.importarDatos(backup);

      final despues = await dao.getCategorias();
      expect(despues.map((c) => c.nombre), antes);
      expect(despues.map((c) => c.nombre), isNot(contains('Ropa')));
      final gym = despues.firstWhere((c) => c.nombre == 'Gimnasio');
      expect((gym.icono, gym.color), ('gimnasio', 0xFF5B8DBE));
    });

    test('un respaldo viejo (sin categorías) arma las de fábrica más las '
        'que usen sus gastos', () async {
      await service.importarDatos({
        'version': 1,
        'datos': {
          'gastosVariables': [
            {
              'id': 1,
              'descripcion': 'Croquetas',
              'monto': 40000,
              'categoria': 'Perro',
              'fecha': DateTime.utc(2026, 1, 5).millisecondsSinceEpoch,
              'notas': null,
              'creadoEn': DateTime.utc(2026, 1, 5).millisecondsSinceEpoch,
            },
          ],
        },
      });
      final nombres = (await db.categoriasDao.getCategorias())
          .map((c) => c.nombre)
          .toList();
      expect(nombres, contains('Perro'));
      expect(nombres, containsAll(['Alimentación', 'Ropa', 'Otros']));
    });

    test('el extra y la estrategia del Plan de pago viajan en el respaldo; '
        'uno viejo sin ellos no cambia nada', () async {
      await PreferenciasPlan.guardarEstrategia(EstrategiaPago.bolaDeNieve);
      await PreferenciasPlan.guardarExtra(250000);
      final backup = await service.exportarDatos();
      expect(backup['planPago'], {
        'estrategia': 'bola_de_nieve',
        'extra': 250000,
      });

      SharedPreferences.setMockInitialValues({});
      await service.importarDatos(backup);
      var prefs = await PreferenciasPlan.leer();
      expect(prefs.estrategia, EstrategiaPago.bolaDeNieve);
      expect(prefs.extra, 250000);

      backup.remove('planPago');
      await PreferenciasPlan.guardarExtra(9000);
      await service.importarDatos(backup);
      prefs = await PreferenciasPlan.leer();
      expect(prefs.extra, 9000);
    });

    test(
      'nombre, apellido, foto y hora del recordatorio diario viajan; '
      'el encendido del recordatorio no, y uno viejo no cambia nada',
      () async {
        final dir = Directory.systemTemp.createTempSync('valtiq_perfil_');
        addTearDown(() => dir.deleteSync(recursive: true));
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('plugins.flutter.io/path_provider'),
              (call) async => dir.path,
            );
        final foto = File('${dir.path}/origen.png')
          ..writeAsBytesSync([1, 2, 3, 4, 5]);
        SharedPreferences.setMockInitialValues({
          'valtiq_perfil_nombre': 'Ana',
          'valtiq_perfil_apellido': 'Pérez Gómez',
          'valtiq_perfil_foto': foto.path,
          'valtiq_recordatorio_diario': true,
          'valtiq_recordatorio_diario_minutos': 7 * 60 + 30,
        });
        final backup = await service.exportarDatos();
        expect(backup['perfil']['nombre'], 'Ana');
        expect(backup['perfil']['fotoExtension'], 'png');
        expect(backup['recordatorioDiarioMinutos'], 7 * 60 + 30);

        // Otro dispositivo, sin perfil y con el recordatorio apagado.
        SharedPreferences.setMockInitialValues({});
        await PerfilService.cargar();
        await service.importarDatos(backup);
        final perfil = PerfilService.perfil.value;
        expect(perfil.nombre, 'Ana');
        expect(perfil.apellido, 'Pérez Gómez');
        expect(File(perfil.rutaFoto!).readAsBytesSync(), [1, 2, 3, 4, 5]);
        final diario = await NotificationService.recordatorioDiario();
        expect(diario.minutos, 7 * 60 + 30);
        expect(diario.activo, isFalse);

        // Un respaldo viejo (sin perfil ni hora) no borra lo que hay.
        backup
          ..remove('perfil')
          ..remove('recordatorioDiarioMinutos');
        await service.importarDatos(backup);
        expect(PerfilService.perfil.value.nombre, 'Ana');
        expect((await NotificationService.recordatorioDiario()).minutos, 450);
      },
    );

    test(
      'exportarDatos → importarDatos: round-trip preserva los montos',
      () async {
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
      },
    );

    test('importarDatos: backup viejo (schemaVersion 9, montos double) se '
        'restaura redondeando en vez de fallar', () async {
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
    });
  });
}
