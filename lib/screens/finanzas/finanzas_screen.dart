import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> {
  String _modo = 'ingresos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Finanzas',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'ingresos', label: Text('Ingresos')),
                    ButtonSegment(value: 'gastos', label: Text('Gastos Fijos')),
                  ],
                  selected: {_modo},
                  onSelectionChanged: (s) =>
                      setState(() => _modo = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.acento;
                        }
                        return null;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _modo == 'ingresos'
                    ? _PanelVacio(
                        mensaje: 'No tienes ingresos registrados',
                        heroTag: 'fab_ingresos',
                        colorSecundario: colorSec,
                      )
                    : _PanelVacio(
                        mensaje: 'No tienes gastos fijos registrados',
                        heroTag: 'fab_gastos',
                        colorSecundario: colorSec,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelVacio extends StatelessWidget {
  const _PanelVacio({
    required this.mensaje,
    required this.heroTag,
    required this.colorSecundario,
  });

  final String mensaje;
  final String heroTag;
  final Color colorSecundario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FloatingActionButton.small(
            heroTag: heroTag,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              mensaje,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorSecundario,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
