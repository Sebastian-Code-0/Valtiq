import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../main.dart';
import '../../theme/theme.dart';
import 'acerca_de_screen.dart';
import 'apariencia_screen.dart';
import 'config_smtp_screen.dart';
import 'presupuestos_screen.dart';
import 'respaldo_screen.dart';
import 'seguridad_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.db});

  final AppDatabase db;

  String _nombreTema(ThemeMode modo) => switch (modo) {
    ThemeMode.light => 'Claro',
    ThemeMode.dark => 'Oscuro',
    _ => 'Sistema',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, modo, _) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Apariencia'),
                  subtitle: Text('Tema: ${_nombreTema(modo)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AparienciaScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Seguridad'),
                  subtitle: const Text('Bloqueo con PIN o biometría'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SeguridadScreen()),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Configuración SMTP'),
                  subtitle: const Text(
                    'Servidor, credenciales y notificaciones',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ConfigSmtpScreen(db: db)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Copia de seguridad'),
                  subtitle: const Text('Exportar o importar tus datos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RespaldoScreen(db: db)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pie_chart_outline),
                  title: const Text('Presupuestos por categoría'),
                  subtitle: const Text('Límites mensuales de gasto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PresupuestosScreen(db: db),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outlined),
                  title: const Text('Acerca de'),
                  subtitle: const Text('Versión, licencia y repositorio'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AcercaDeScreen()),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
