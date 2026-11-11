import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valtiq/theme/theme.dart';
import 'package:valtiq/utils/selector_hora.dart';

void main() {
  test('formatHora12: siempre 12 horas con a. m. / p. m.', () {
    expect(formatHora12(0, 0), '12:00 a. m.');
    expect(formatHora12(9, 5), '9:05 a. m.');
    expect(formatHora12(12, 0), '12:00 p. m.');
    expect(formatHora12(22, 55), '10:55 p. m.');
    expect(formatHora12(23, 59), '11:59 p. m.');
  });

  Future<({int hora, int minuto})?> abrirYElegir(
    WidgetTester tester, {
    required int hora,
    required int minuto,
    required Future<void> Function() acciones,
    Size tamano = const Size(360, 640),
  }) async {
    tester.view.physicalSize = tamano;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    ({int hora, int minuto})? resultado;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async => resultado = await mostrarSelectorHora(
                  context,
                  hora: hora,
                  minuto: minuto,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await acciones();
    await tester.pumpAndSettle();
    return resultado;
  }

  testWidgets('elegir 10, 55 y p. m. devuelve 22:55 (cabe en un celular '
      'angosto sin desbordarse)', (tester) async {
    final r = await abrirYElegir(
      tester,
      hora: 12,
      minuto: 0,
      acciones: () async {
        await tester.tap(find.text('10').first);
        await tester.tap(find.text('55'));
        await tester.tap(find.text('p. m.'));
        await tester.pump();
        expect(find.text('10:55 p. m.'), findsOneWidget);
        await tester.tap(find.text('Aceptar'));
      },
    );
    expect(r, (hora: 22, minuto: 55));
  });

  testWidgets('12 a. m. es medianoche (0) y el ajuste fino suma de a 1 '
      'minuto', (tester) async {
    final r = await abrirYElegir(
      tester,
      hora: 15,
      minuto: 58,
      acciones: () async {
        await tester.tap(find.text('12'));
        await tester.tap(find.text('a. m.'));
        await tester.pump();
        // 58 → 59 → 00 (da la vuelta sin cambiar la hora)
        await tester.tap(find.byIcon(Icons.add));
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
        expect(find.text('12:00 a. m.'), findsOneWidget);
        await tester.tap(find.text('Aceptar'));
      },
    );
    expect(r, (hora: 0, minuto: 0));
  });

  testWidgets('Cancelar no devuelve nada', (tester) async {
    final r = await abrirYElegir(
      tester,
      hora: 8,
      minuto: 30,
      acciones: () => tester.tap(find.text('Cancelar')),
    );
    expect(r, isNull);
  });
}
