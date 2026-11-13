import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/db/daos/categorias_dao.dart';
import 'package:valtiq/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Categoria> crearCasa() async {
    final id = await db.categoriasDao.crear(
      nombre: '  Casa ',
      icono: 'hogar',
      color: 0xFFA6754D,
    );
    return (await db.categoriasDao.getCategorias()).firstWhere(
      (c) => c.id == id,
    );
  }

  Future<void> gasto(String descripcion, int monto, String categoria) =>
      db.gastosVariablesDao.insertGastoVariable(
        GastosVariablesCompanion.insert(
          descripcion: descripcion,
          monto: monto,
          categoria: categoria,
          fecha: DateTime.utc(2026, 11, 1),
        ),
      );

  Future<void> limite(String categoria, int monto) =>
      db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion.insert(
          categoria: categoria,
          limiteMensual: monto,
        ),
      );

  Future<List<(String, String)>> gastos() async => [
    for (final g in await db.gastosVariablesDao.getAllGastosVariables())
      (g.descripcion, g.categoria),
  ];

  test('crear: sin espacios de más, al final de la lista', () async {
    final casa = await crearCasa();
    expect(casa.nombre, 'Casa');
    final todas = await db.categoriasDao.getCategorias();
    expect(todas.last.nombre, 'Casa');
    expect(casa.orden, todas.length - 1);
  });

  test('existeNombre no distingue mayúsculas ni espacios', () async {
    final casa = await crearCasa();
    expect(await db.categoriasDao.existeNombre('casa'), isTrue);
    expect(await db.categoriasDao.existeNombre(' CASA '), isTrue);
    expect(
      await db.categoriasDao.existeNombre('casa', salvoId: casa.id),
      isFalse,
    );
    expect(await db.categoriasDao.existeNombre('Finca'), isFalse);
  });

  test('renombrar cambia también sus gastos y su presupuesto', () async {
    final casa = await crearCasa();
    await gasto('Bombillo', 8000, 'Casa');
    await gasto('Pan', 3000, 'Alimentación');
    await limite('Casa', 100000);

    await db.categoriasDao.actualizar(
      casa,
      nombre: 'Hogar y casa',
      icono: 'muebles',
      color: 0xFF5B8DBE,
    );

    expect(await gastos(), [
      ('Bombillo', 'Hogar y casa'),
      ('Pan', 'Alimentación'),
    ]);
    final p = (await db.presupuestosCategoriasDao.getAllPresupuestos()).single;
    expect(p.categoria, 'Hogar y casa');
    final editada = (await db.categoriasDao.getCategorias()).firstWhere(
      (c) => c.id == casa.id,
    );
    expect((editada.icono, editada.color), ('muebles', 0xFF5B8DBE));
  });

  test('"Otros" no se puede renombrar (sí cambiar ícono y color) ni '
      'borrar', () async {
    final otros = (await db.categoriasDao.getCategorias()).firstWhere(
      (c) => c.nombre == CategoriasDao.nombreOtros,
    );
    await db.categoriasDao.actualizar(
      otros,
      nombre: 'Varios',
      icono: 'compras',
      color: 0xFF7A9E5B,
    );
    final despues = (await db.categoriasDao.getCategorias()).firstWhere(
      (c) => c.id == otros.id,
    );
    expect(despues.nombre, CategoriasDao.nombreOtros);
    expect(despues.icono, 'compras');
    expect(
      () => db.categoriasDao.borrar(despues, moverAOtros: false),
      throwsStateError,
    );
  });

  test('usoDe: cuántos gastos, cuánto suman y su límite', () async {
    await crearCasa();
    await gasto('Bombillo', 8000, 'Casa');
    await gasto('Escoba', 12000, 'Casa');
    await limite('Casa', 100000);
    final uso = await db.categoriasDao.usoDe('Casa');
    expect(
      (uso.gastos, uso.totalGastos, uso.limiteMensual),
      (2, 20000, 100000),
    );
    expect(uso.vacia, isFalse);
    expect((await db.categoriasDao.usoDe('Ropa')).vacia, isTrue);
  });

  test(
    'borrar con sus gastos: se borran los gastos y el límite, nada más',
    () async {
      final casa = await crearCasa();
      await gasto('Bombillo', 8000, 'Casa');
      await gasto('Escoba', 12000, 'Casa');
      await gasto('Pan', 3000, 'Alimentación');
      await limite('Casa', 100000);
      await limite('Alimentación', 300000);

      final r = await db.categoriasDao.borrar(casa, moverAOtros: false);

      expect(r.nombre, 'Casa');
      expect(
        (r.uso.gastos, r.uso.totalGastos, r.uso.limiteMensual),
        (2, 20000, 100000),
      );
      expect(r.gastosMovidos, isFalse);
      expect(await gastos(), [('Pan', 'Alimentación')]);
      expect(
        (await db.presupuestosCategoriasDao.getAllPresupuestos()).map(
          (p) => p.categoria,
        ),
        ['Alimentación'],
      );
      expect(
        (await db.categoriasDao.getCategorias()).map((c) => c.nombre),
        isNot(contains('Casa')),
      );
    },
  );

  test('borrar pasando los gastos a "Otros": los gastos se quedan', () async {
    final casa = await crearCasa();
    await gasto('Bombillo', 8000, 'Casa');
    await limite('Casa', 100000);

    final r = await db.categoriasDao.borrar(casa, moverAOtros: true);

    expect(r.gastosMovidos, isTrue);
    expect(await gastos(), [('Bombillo', CategoriasDao.nombreOtros)]);
    expect(await db.presupuestosCategoriasDao.getAllPresupuestos(), isEmpty);
  });
}
