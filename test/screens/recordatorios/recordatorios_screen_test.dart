import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/recordatorios/recordatorio_form.dart';
import 'package:valtiq/screens/recordatorios/recordatorios_screen.dart';
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
  final hoy = DateTime.now();
  DateTime enDias(int n) =>
      normalizarFechaCivil(DateTime(hoy.year, hoy.month, hoy.day + n));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  /// Uno vencido, uno cercano (dentro de su anticipación), uno lejano y uno
  /// inactivo.
  Future<({int vencido, int cerca, int lejos, int inactivo})> sembrar() async {
    final dao = db.recordatoriosDao;
    final vencido = await dao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Pagar tarjeta',
        fechaAlerta: enDias(-4),
        referenciaTabla: const Value('deuda'),
      ),
    );
    final cerca = await dao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Cobrar a Pedro con un título bastante largo para probar',
        fechaAlerta: enDias(2),
        repetir: const Value(true),
        horaAviso: const Value(8),
        minutoAviso: const Value(30),
      ),
    );
    final lejos = await dao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Arriendo',
        fechaAlerta: enDias(20),
      ),
    );
    final inactivo = await dao.insertRecordatorio(
      RecordatoriosCompanion.insert(
        titulo: 'Viejo',
        fechaAlerta: enDias(-30),
        activo: const Value(false),
      ),
    );
    return (vencido: vencido, cerca: cerca, lejos: lejos, inactivo: inactivo);
  }

  Future<void> montar(WidgetTester tester, Size tamano, {Widget? home}) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: RepaintBoundary(child: home ?? RecordatoriosScreen(db: db)),
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

  for (final (nombre, tamano) in const [
    ('celular (360x640)', Size(360, 640)),
    ('PC (1102x768)', Size(1102, 768)),
  ]) {
    testWidgets('Recordatorios en $nombre: las dos pestañas y el formulario '
        'se dibujan sin desbordarse', (tester) async {
      final ids = await sembrar();
      await montar(tester, tamano);
      final w = tamano.width.round();
      expect(tester.takeException(), isNull);
      // Vencido + cercano = 2 pendientes (el lejano todavía no).
      expect(find.text('2 PENDIENTES'), findsOneWidget);
      expect(find.text('Pagar tarjeta'), findsOneWidget);
      expect(find.text('Arriendo'), findsOneWidget);
      expect(find.text('Viejo'), findsNothing);
      expect(find.textContaining('Vencido'), findsOneWidget);
      expect(find.text('En 2 días'), findsOneWidget);
      await captura(tester, 'recordatorios-$w');

      await tester.tap(find.text('Inactivos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Viejo'), findsOneWidget);
      expect(find.text('Pagar tarjeta'), findsNothing);
      expect(
        tamano.width < 600
            ? find.byTooltip('Vaciar inactivos')
            : find.text('Vaciar inactivos'),
        findsOneWidget,
      );
      await captura(tester, 'recordatorios-inactivos-$w');
      await _cerrar(tester);

      await montar(
        tester,
        tamano,
        home: RecordatorioForm(
          db: db,
          recordatorio: (await db.recordatoriosDao.getRecordatorioById(
            ids.cerca,
          ))!,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Editar recordatorio'), findsOneWidget);
      await captura(tester, 'recordatorio-form-$w');
      await _cerrar(tester);
    });
  }

  testWidgets('inactivar desde el menú lo pasa a Inactivos, y "Vaciar '
      'inactivos" pide confirmación y los borra', (tester) async {
    final ids = await sembrar();
    await montar(tester, const Size(1366, 768));

    // El primero de la lista es el más antiguo: el vencido.
    await tester.tap(find.byTooltip('Acciones').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inactivar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      (await db.recordatoriosDao.getRecordatorioById(ids.vencido))!.activo,
      isFalse,
    );
    // Se va el aviso flotante antes de seguir tocando.
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('1 PENDIENTE'), findsOneWidget);

    await tester.tap(find.text('Inactivos'));
    await tester.pumpAndSettle();
    expect(find.text('Pagar tarjeta'), findsOneWidget);
    await tester.tap(find.text('Vaciar inactivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(
      await db.recordatoriosDao.getRecordatorioById(ids.inactivo),
      isNotNull,
    );

    await tester.tap(find.text('Vaciar inactivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar todos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(await db.recordatoriosDao.getRecordatorioById(ids.inactivo), isNull);
    expect(await db.recordatoriosDao.getRecordatorioById(ids.vencido), isNull);
    expect(await db.recordatoriosDao.getRecordatorioById(ids.lejos), isNotNull);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await _cerrar(tester);
  });
}
