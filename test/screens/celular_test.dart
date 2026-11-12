import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/barra_inferior.dart';
import 'package:valtiq/screens/config/settings_screen.dart';
import 'package:valtiq/screens/deudas/deudas_screen.dart';
import 'package:valtiq/screens/recordatorios/recordatorios_screen.dart';
import 'package:valtiq/screens/shell.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/fecha_civil.dart';

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

  Future<void> montar(WidgetTester tester, Size tamano, ThemeData tema) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: tema,
        home: RepaintBoundary(child: ShellScreen(db: db)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
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

  Future<void> sembrar() async {
    final hoy = normalizarFechaCivil(DateTime.now());
    await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Banco',
        montoOriginal: 2000000,
        fechaPrestamo: hoy,
        tasaInteres: const Value(2),
        tipoInteres: const Value('mensual'),
      ),
    );
    // Uno vencido (cuenta en la insignia) y uno lejano (no cuenta).
    for (final (titulo, dias) in [('Pagar arriendo', -2), ('Seguro', 40)]) {
      await db.recordatoriosDao.insertRecordatorio(
        RecordatoriosCompanion.insert(
          titulo: titulo,
          fechaAlerta: hoy.add(Duration(days: dias)),
        ),
      );
    }
  }

  for (final (nombre, tamano) in const [
    ('celular angosto (320x640)', Size(320, 640)),
    ('celular (360x780)', Size(360, 780)),
    ('celular grande (412x900)', Size(412, 900)),
  ]) {
    testWidgets('en $nombre la barra flotante lleva a las cinco secciones '
        'sin desbordarse', (tester) async {
      await sembrar();
      await montar(tester, tamano, AppTheme.dark());
      expect(tester.takeException(), isNull);

      final barra = find.byType(BarraInferior);
      expect(barra, findsOneWidget);
      // Flota: no toca los lados ni el fondo de la pantalla.
      final pildora = tester.getRect(
        find.descendant(of: barra, matching: find.byType(Row)).first,
      );
      expect(pildora.left, greaterThanOrEqualTo(BarraInferior.margen));
      expect(
        pildora.right,
        lessThanOrEqualTo(tamano.width - BarraInferior.margen),
      );
      expect(
        pildora.bottom,
        lessThanOrEqualTo(tamano.height - BarraInferior.margen),
      );
      // La insignia cuenta solo el recordatorio vencido.
      expect(find.descendant(of: barra, matching: find.text('1')), findsOne);
      await captura(tester, 'celular-inicio-${tamano.width.round()}');

      for (final (seccion, tipo) in [
        ('Deudas', DeudasScreen),
        ('Avisos', RecordatoriosScreen),
      ]) {
        await tester.tap(
          find.descendant(of: barra, matching: find.text(seccion)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: seccion);
        expect(find.byType(tipo), findsOneWidget);
        await captura(
          tester,
          'celular-${seccion.toLowerCase()}-${tamano.width.round()}',
        );
      }
      for (final seccion in ['Préstamos', 'Finanzas', 'Inicio']) {
        await tester.tap(
          find.descendant(of: barra, matching: find.text(seccion)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: seccion);
      }
      await _cerrar(tester);
    });
  }

  testWidgets('en celular, tema claro: la barra se dibuja sin errores', (
    tester,
  ) async {
    await sembrar();
    await montar(tester, const Size(360, 780), AppTheme.light());
    expect(tester.takeException(), isNull);
    await captura(tester, 'celular-inicio-claro');
    await _cerrar(tester);
  });

  testWidgets('en celular, a Ajustes se entra tocando la foto de Inicio', (
    tester,
  ) async {
    await montar(tester, const Size(360, 780), AppTheme.dark());
    expect(find.byType(SettingsScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('inicio-ajustes')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await _cerrar(tester);
  });
}
