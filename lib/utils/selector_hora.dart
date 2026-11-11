import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// "10:55 p. m." — siempre en formato de 12 horas con a. m. / p. m., sin
/// importar cómo esté configurado el dispositivo (el formato de 24 horas
/// confunde a mucha gente).
String formatHora12(int hora, int minuto) {
  final h12 = hora % 12 == 0 ? 12 : hora % 12;
  final mm = minuto.toString().padLeft(2, '0');
  return '$h12:$mm ${hora < 12 ? 'a. m.' : 'p. m.'}';
}

/// Abre el selector de hora de Valtiq y devuelve la hora elegida en formato
/// interno de 24 h (`hora` 0–23, `minuto` 0–59), o `null` si se canceló.
///
/// Reemplaza al reloj circular de Material (`showTimePicker`), que resultó
/// difícil de usar: aquí todo se elige tocando botones — la hora (1 a 12),
/// los minutos (de 5 en 5, con − y + para ajustar de a 1) y a. m. / p. m.
Future<({int hora, int minuto})?> mostrarSelectorHora(
  BuildContext context, {
  required int hora,
  required int minuto,
  String titulo = 'Elige la hora',
}) {
  return showDialog<({int hora, int minuto})>(
    context: context,
    builder: (_) =>
        _SelectorHoraDialog(hora: hora, minuto: minuto, titulo: titulo),
  );
}

class _SelectorHoraDialog extends StatefulWidget {
  const _SelectorHoraDialog({
    required this.hora,
    required this.minuto,
    required this.titulo,
  });

  final int hora;
  final int minuto;
  final String titulo;

  @override
  State<_SelectorHoraDialog> createState() => _SelectorHoraDialogState();
}

class _SelectorHoraDialogState extends State<_SelectorHoraDialog> {
  late int _hora12 = widget.hora % 12 == 0 ? 12 : widget.hora % 12;
  late int _minuto = widget.minuto;
  late bool _pm = widget.hora >= 12;

  int get _hora24 => (_hora12 % 12) + (_pm ? 12 : 0);

  void _ajustarMinuto(int delta) =>
      setState(() => _minuto = (_minuto + delta) % 60);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    return AlertDialog(
      title: Text(widget.titulo),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // FittedBox: con letra grande del sistema la hora se encoge
              // en vez de partirse en dos renglones.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatHora12(_hora24, _minuto),
                  style: monoStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: c.acento,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.wb_sunny_outlined),
                    label: Text('a. m.'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.nightlight_outlined),
                    label: Text('p. m.'),
                  ),
                ],
                selected: {_pm},
                onSelectionChanged: (s) => setState(() => _pm = s.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: c.acentoRelleno,
                  selectedForegroundColor: c.sobreAcento,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Hora', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              _Rejilla(
                valores: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
                seleccionado: _hora12,
                etiqueta: (v) => '$v',
                onElegir: (v) => setState(() => _hora12 = v),
              ),
              const SizedBox(height: AppSpacing.md),
              // Los botones de la rejilla van de 5 en 5; − y + ajustan de a
              // 1 minuto para una hora exacta (10:53). Van en la misma fila
              // del título para que siempre queden a la vista.
              Row(
                children: [
                  Expanded(
                    child: Text('Minutos', style: theme.textTheme.labelLarge),
                  ),
                  IconButton.outlined(
                    onPressed: () => _ajustarMinuto(-1),
                    tooltip: 'Un minuto menos',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton.outlined(
                    onPressed: () => _ajustarMinuto(1),
                    tooltip: 'Un minuto más',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              _Rejilla(
                valores: const [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55],
                seleccionado: _minuto,
                etiqueta: (v) => v.toString().padLeft(2, '0'),
                onElegir: (v) => setState(() => _minuto = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.pop(context, (hora: _hora24, minuto: _minuto)),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}

/// Rejilla de 6 columnas de botones; el elegido se rellena de vino.
class _Rejilla extends StatelessWidget {
  const _Rejilla({
    required this.valores,
    required this.seleccionado,
    required this.etiqueta,
    required this.onElegir,
  });

  final List<int> valores;
  final int seleccionado;
  final String Function(int) etiqueta;
  final ValueChanged<int> onElegir;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1.25,
      children: [
        for (final v in valores)
          Material(
            color: v == seleccionado ? c.acentoRelleno : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              side: BorderSide(
                color: v == seleccionado ? c.acentoRelleno : c.divisor,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onElegir(v),
              child: Center(
                child: Text(
                  etiqueta(v),
                  style: monoStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: v == seleccionado ? c.sobreAcento : c.texto,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
