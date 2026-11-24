import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valtiq/db/database.dart';
import 'package:valtiq/main.dart' as app;
import 'package:valtiq/services/app_lock_service.dart';
import 'package:valtiq/services/borrado_service.dart';
import 'package:valtiq/utils/categoria_gasto.dart';
import 'package:valtiq/services/interes_calculator.dart';
import 'package:valtiq/services/perfil_service.dart';
import 'package:valtiq/utils/fecha_civil.dart';
import 'package:valtiq/utils/format.dart';
import 'package:valtiq/utils/preferencia_menu.dart';
import 'package:valtiq/utils/tasa_input.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('borrarTodo deja la base vacía y las preferencias de fábrica', () async {
    SharedPreferences.setMockInitialValues({
      'valtiq_perfil_nombre': 'Sofía',
      'valtiq_theme': 'dark',
      'valtiq_menu_superior': true,
      'valtiq_plan_extra': 50000,
    });
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final hoy = normalizarFechaCivil(DateTime.now());
    final deuda = await db.deudasDao.insertDeuda(
      DeudasCompanion.insert(
        acreedorNombre: 'Juan',
        montoOriginal: 100000,
        fechaPrestamo: hoy,
      ),
    );
    await db.pagosDeudaDao.insertPago(
      PagosDeudaCompanion.insert(
        deudaId: deuda,
        montoAbonado: 1000,
        fechaPago: hoy,
      ),
    );
    await db.prestamosDao.insertPrestamo(
      PrestamosCompanion.insert(
        deudorNombre: 'Ana',
        montoPrestado: 5000,
        tasaInteres: const Value(2),
        fechaPrestamo: hoy,
      ),
    );
    await AppLockService.activarConPin('1234');
    await PerfilService.cargar();
    app.themeModeNotifier.value = ThemeMode.dark;
    montosOcultosNotifier.value = true;
    menuSuperiorNotifier.value = true;

    await BorradoService.borrarTodo(db);

    for (final tabla in db.allTables) {
      // Las categorías vuelven a las de fábrica (como recién instalada).
      if (tabla == db.categorias) continue;
      expect(
        await db.select(tabla).get(),
        isEmpty,
        reason: tabla.actualTableName,
      );
    }
    expect(
      (await db.categoriasDao.getCategorias()).map((c) => c.nombre),
      CategoriaGasto.nombres,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
    expect(await AppLockService.bloqueoActivo(), isFalse);
    expect(PerfilService.perfil.value.nombre, isEmpty);
    expect(app.themeModeNotifier.value, ThemeMode.system);
    expect(montosOcultosNotifier.value, isFalse);
    expect(menuSuperiorNotifier.value, isFalse);
  });

  test('aPesos: un resultado gigante o infinito se queda en el techo, no se '
      'aplasta al entero máximo ni revienta', () {
    expect(InteresCalculator.aPesos(1234.6), 1235);
    expect(InteresCalculator.aPesos(1e30), 9000000000000000);
    expect(InteresCalculator.aPesos(double.infinity), 9000000000000000);
    expect(InteresCalculator.aPesos(double.nan), 0);
    // El peor caso que se puede escribir (monto y tasa máximos, compuesto,
    // 50 años) sigue dando un número que se puede sumar con otros.
    final interes = InteresCalculator.calcularInteresCompuesto(
      monto: 999999999999,
      tasaInteres: maxTasa,
      tipoInteres: 'mensual',
      fechaInicio: DateTime.utc(1976),
      fechaFin: DateTime.utc(2026),
    );
    expect(interes, 9000000000000000);
    expect(interes * 100 > 0, isTrue);
  });

  test('validarTasa: vacío vale (sin interés); negativa, texto o más de 500 '
      'no', () {
    expect(validarTasa(''), isNull);
    expect(validarTasa('2,5'), isNull);
    expect(validarTasa('500'), isNull);
    expect(validarTasa('501'), isNotNull);
    expect(validarTasa('-1'), isNotNull);
    expect(validarTasa('abc'), isNotNull);
    expect(tasaParaCampo(0), '');
    expect(tasaParaCampo(2), '2');
    expect(tasaParaCampo(2.5), '2,5');
  });
}
