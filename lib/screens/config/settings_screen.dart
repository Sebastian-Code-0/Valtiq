import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../main.dart';
import '../../services/notification_service.dart';
import '../../theme/theme.dart';
import 'apariencia_screen.dart';
import 'config_smtp_screen.dart';

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
                    MaterialPageRoute(
                      builder: (_) => const AparienciaScreen(),
                    ),
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
                      builder: (_) => ConfigSmtpScreen(db: db),
                    ),
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active),
                    title: const Text('Probar notificación directa (debug)'),
                    subtitle: const Text('Muestra una notificación YA, sin worker'),
                    onTap: () async {
                      await NotificationService.notificacionDePrueba();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificación directa enviada'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
