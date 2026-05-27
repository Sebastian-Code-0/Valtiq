import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../../theme/theme.dart';

class AparienciaScreen extends StatefulWidget {
  const AparienciaScreen({super.key});

  @override
  State<AparienciaScreen> createState() => _AparienciaScreenState();
}

class _AparienciaScreenState extends State<AparienciaScreen> {
  ThemeMode _modoActual = themeModeNotifier.value;

  Future<void> _cambiarTema(ThemeMode modo) async {
    setState(() => _modoActual = modo);
    themeModeNotifier.value = modo;
    final prefs = await SharedPreferences.getInstance();
    final key = switch (modo) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString('valtiq_theme', key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto),
                        label: Text('Sistema'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode),
                        label: Text('Oscuro'),
                      ),
                    ],
                    selected: {_modoActual},
                    onSelectionChanged: (s) => _cambiarTema(s.first),
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor:
                          AppColors.acento.withValues(alpha: 0.15),
                      selectedForegroundColor: AppColors.acento,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.construction_outlined,
                        size: 18,
                        color: AppColors.textoSecundarioClaro,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Más opciones',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Próximamente: fuentes, colores personalizados y más.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textoSecundarioClaro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
