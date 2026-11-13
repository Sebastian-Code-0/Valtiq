import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/config/acerca_de_screen.dart';
import 'package:valtiq/screens/config/como_funciona_screen.dart';
import 'package:valtiq/screens/config/config_smtp_screen.dart';
import 'package:valtiq/screens/config/notificaciones_screen.dart';
import 'package:valtiq/screens/config/perfil_screen.dart';
import 'package:valtiq/screens/config/presupuestos_screen.dart';
import 'package:valtiq/screens/config/respaldo_screen.dart';
import 'package:valtiq/screens/config/seguridad_screen.dart';
import 'package:valtiq/screens/config/settings_screen.dart';
import 'package:valtiq/services/app_lock_service.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/selector_pildoras.dart';

// Los StreamBuilder de drift dejan un Timer de limpieza pendiente al
// desmontarse; este pump adicional lo drena.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    PerfilService.perfil.value = const Perfil(nombre: 'Sofía');
  });
  tearDown(() async {
    PerfilService.perfil.value = const Perfil();
    await db.close();
  });

  /// Monta una sección como se ve dentro de Ajustes (sin barra propia).
  Future<void> montar(WidgetTester tester, Size tamano, Widget seccion) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(child: AjustesEmbebido(child: seccion)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Guarda una captura si se pide con CAPTURAS=<carpeta>.
  Future<void> captura(WidgetTester tester, String nombre) async {
    final carpeta = Platform.environment['CAPTURAS'];
    if (carpeta == null) return;
    await tester.runAsync(() async {
      final limite =
          tester.renderObject(find.byType(RepaintBoundary).first)
              as RenderRepaintBoundary;
      final imagen = await limite.toImage();
      final bytes = await imagen.toByteData(format: ImageByteFormat.png);
      File('$carpeta/$nombre.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  for (final (nombre, tamano, sufijo) in const [
    ('celular (360x640)', Size(360, 640), 'celular'),
    ('PC (1102x768)', Size(1102, 768), 'pc'),
  ]) {
    testWidgets('secciones de Ajustes en $nombre se dibujan sin desbordarse', (
      tester,
    ) async {
      final hoy = DateTime.now();
      await db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion.insert(
          categoria: 'Alimentación',
          limiteMensual: 300000,
        ),
      );
      await db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion.insert(
          categoria: 'Transporte',
          limiteMensual: 100000,
        ),
      );
      for (final (categoria, monto) in [
        ('Alimentación', 120000),
        ('Transporte', 150000),
      ]) {
        await db.gastosVariablesDao.insertGastoVariable(
          GastosVariablesCompanion.insert(
            descripcion: 'Prueba',
            monto: monto,
            categoria: categoria,
            fecha: DateTime.utc(hoy.year, hoy.month, 1),
          ),
        );
      }
      await tester.runAsync(() => AppLockService.activarConPin('1234'));

      final secciones = <String, Widget>{
        'perfil': const PerfilScreen(),
        'notificaciones': NotificacionesScreen(db: db),
        'presupuestos': PresupuestosScreen(db: db),
        'seguridad': const SeguridadScreen(),
        'respaldo': RespaldoScreen(db: db),
        'como-funciona': const ComoFuncionaScreen(),
        'correo': ConfigSmtpScreen(db: db),
        'acerca-de': const AcercaDeScreen(),
      };
      for (final s in secciones.entries) {
        await montar(
          tester,
          tamano,
          KeyedSubtree(key: ValueKey(s.key), child: s.value),
        );
        expect(tester.takeException(), isNull, reason: s.key);
        await captura(tester, 'ajustes-${s.key}-$sufijo');
        await _cerrar(tester);
      }
    });
  }

  testWidgets('Presupuestos: una sola tarjeta, con lo gastado del mes y '
      '"Superado" cuando se pasa del límite', (tester) async {
    final hoy = DateTime.now();
    await db.presupuestosCategoriasDao.upsertPresupuesto(
      PresupuestosCategoriasCompanion.insert(
        categoria: 'Alimentación',
        limiteMensual: 300000,
      ),
    );
    await db.presupuestosCategoriasDao.upsertPresupuesto(
      PresupuestosCategoriasCompanion.insert(
        categoria: 'Transporte',
        limiteMensual: 100000,
      ),
    );
    for (final (categoria, monto) in [
      ('Alimentación', 120000),
      ('Transporte', 150000),
    ]) {
      await db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: 'Prueba',
          monto: monto,
          categoria: categoria,
          fecha: DateTime.utc(hoy.year, hoy.month, 1),
        ),
      );
    }
    await montar(tester, const Size(412, 2400), PresupuestosScreen(db: db));
    expect(find.byType(Card), findsOneWidget);
    expect(find.text('17 CATEGORÍAS · 2 CON LÍMITE'), findsOneWidget);
    expect(find.text('Llevas \$120.000 este mes'), findsOneWidget);
    expect(find.text('Superado por \$50.000 este mes'), findsOneWidget);
    expect(find.text('Sin límite'), findsWidgets);
    await _cerrar(tester);
  });

  testWidgets('Seguridad: el tiempo de bloqueo se elige con píldoras y se '
      'guarda', (tester) async {
    await tester.runAsync(() => AppLockService.activarConPin('1234'));
    await montar(tester, const Size(412, 900), const SeguridadScreen());
    expect(find.byType(GrupoPildoras<Duration>), findsOneWidget);
    expect(find.byType(DropdownButton<Duration>), findsNothing);
    await tester.tap(find.text('5 min'));
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(AppLockService.timeoutReloqueo),
      const Duration(minutes: 5),
    );
    await _cerrar(tester);
  });

  testWidgets('Notificaciones: los consejos están siempre a la vista (no '
      'plegados)', (tester) async {
    // La pantalla de celular llama al plugin de Android, que no existe en
    // las pruebas: se monta solo la sección de consejos.
    await montar(
      tester,
      const Size(412, 900),
      const Scaffold(
        body: SingleChildScrollView(child: ConsejosNotificaciones()),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Si no te llegan los avisos'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
    for (final consejo in [
      'Quítale la restricción de batería',
      'Activa el "Inicio automático"',
      'No uses "Forzar detención"',
      'Los correos salen al abrir Valtiq',
    ]) {
      expect(find.text(consejo), findsOneWidget);
    }
    await captura(tester, 'ajustes-consejos-celular');
  });

  testWidgets('Correo: elegir el proveedor llena servidor y puerto, y con '
      'Gmail sale el aviso de la contraseña de aplicación', (tester) async {
    await montar(tester, const Size(412, 2000), ConfigSmtpScreen(db: db));
    expect(find.text('Gmail pide una contraseña de aplicación'), findsNothing);
    await tester.tap(find.text('Gmail'));
    await tester.pumpAndSettle();
    expect(find.text('smtp.gmail.com'), findsWidgets);
    expect(
      find.text('Gmail pide una contraseña de aplicación'),
      findsOneWidget,
    );
    await tester.tap(find.text('Outlook'));
    await tester.pumpAndSettle();
    expect(find.text('smtp.office365.com'), findsOneWidget);
    expect(find.text('Gmail pide una contraseña de aplicación'), findsNothing);
    await _cerrar(tester);
  });
}
