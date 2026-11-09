import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/screens/deudas/deuda_detalle.dart';

AppDatabase _createInMemoryDb() => AppDatabase(NativeDatabase.memory());

// Ver presupuestos_flow_test.dart: los StreamBuilder de drift dejan un Timer
// de limpieza pendiente al desmontarse; este pump adicional lo drena para
// que el test no falle por un timer "colgado" aunque la app funcione bien.
Future<void> _cerrar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = _createInMemoryDb();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'Registrar un abono por el saldo exacto marca la deuda como pagada '
    '(saldoPendienteActual <= 0, sin margen de redondeo)',
    (tester) async {
      final deudaId = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Banco Test',
          montoOriginal: 100000,
          fechaPrestamo: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: DeudaDetalle(db: db, deudaId: deudaId)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Registrar abono'));
      await tester.pumpAndSettle();

      // Abono por el 100% del saldo pendiente (sin interés: saldo == monto
      // original == 100000 exactos, aritmética entera sin residuo posible).
      await tester.enterText(find.byType(TextFormField).first, '100000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      // pumpAndSettle() aquí avanzaría el reloj virtual hasta que el SnackBar
      // de éxito (dura 4s) aparezca Y se cierre solo, así que el texto ya no
      // estaría cuando se verifica. Un pump puntual lo captura mientras está
      // visible; el pumpAndSettle final más abajo lo deja terminar su ciclo.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.textContaining('ha sido pagada por completo'), findsOneWidget);

      final deuda = await db.deudasDao.getDeudaById(deudaId);
      expect(deuda!.estado, 'pagada');

      await tester.pumpAndSettle();
      await _cerrar(tester);
    },
  );

  testWidgets(
    r'Registrar un abono $1 por debajo del saldo NO marca la deuda como pagada',
    (tester) async {
      final deudaId = await db.deudasDao.insertDeuda(
        DeudasCompanion.insert(
          acreedorNombre: 'Banco Test',
          montoOriginal: 100000,
          fechaPrestamo: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: DeudaDetalle(db: db, deudaId: deudaId)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Registrar abono'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '99999');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Guardar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('ha sido pagada por completo'), findsNothing);

      final deuda = await db.deudasDao.getDeudaById(deudaId);
      expect(deuda!.estado, 'activa');

      await _cerrar(tester);
    },
  );
}
