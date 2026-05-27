import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../db/database.dart';
import '../../main.dart';
import '../../theme/theme.dart';
import 'config_smtp_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette_outlined,
                        color: AppColors.acento,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Apariencia',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                      selectedBackgroundColor: AppColors.acento.withValues(
                        alpha: 0.15,
                      ),
                      selectedForegroundColor: AppColors.acento,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Configuración SMTP'),
              subtitle: const Text('Servidor, credenciales y notificaciones'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfigSmtpScreen(db: widget.db),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
