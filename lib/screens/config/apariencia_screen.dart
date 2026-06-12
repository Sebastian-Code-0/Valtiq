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
  Color _acentoActual = acentoNotifier.value;

  Future<void> _cambiarAcento(Color color) async {
    setState(() => _acentoActual = color);
    acentoNotifier.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'valtiq_acento',
      color.toARGB32().toRadixString(16),
    );
  }

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
                      selectedBackgroundColor: acentoNotifier.value.withValues(alpha: 0.15),
                      selectedForegroundColor: acentoNotifier.value,
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
                  Text(
                    'Color de acento',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _coloresAcento.map((opcion) {
                      final seleccionado = _acentoActual.toARGB32() ==
                          opcion.color.toARGB32();
                      return GestureDetector(
                        onTap: () => _cambiarAcento(opcion.color),
                        child: Tooltip(
                          message: opcion.nombre,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: opcion.color,
                              shape: BoxShape.circle,
                              border: seleccionado
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: seleccionado
                                ? Icon(
                                    Icons.check,
                                    size: 20,
                                    color: ThemeData.estimateBrightnessForColor(
                                                opcion.color) ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
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

const _coloresAcento = [
  (color: Color(0xFF2DD4A0), nombre: 'Menta'),
  (color: Color(0xFF6366F1), nombre: 'Índigo'),
  (color: Color(0xFFF59E0B), nombre: 'Ámbar'),
  (color: Color(0xFFEC4899), nombre: 'Rosa'),
  (color: Color(0xFF38BDF8), nombre: 'Cielo'),
  (color: Color(0xFFF97316), nombre: 'Coral'),
];
