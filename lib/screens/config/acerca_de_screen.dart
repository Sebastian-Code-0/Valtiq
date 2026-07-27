import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/theme.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  Future<void> _abrirUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo_icono.png',
                    height: 64,
                    color: AppColors.acento,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Valtiq',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '...';
                      return Text(
                        'Versión $version',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorSec,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Gestión de préstamos, deudas e ingresos personales. '
                    'Tus datos se almacenan localmente, sin nube.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Licencia'),
                  subtitle: const Text('GNU General Public License v3.0'),
                  trailing: Icon(Icons.chevron_right, color: colorSec),
                  onTap: () =>
                      _abrirUrl('https://www.gnu.org/licenses/gpl-3.0.html'),
                ),
                const Divider(height: 1, indent: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Código fuente'),
                  subtitle: const Text('github.com/Sebastian-Code-0/Valtiq'),
                  trailing: Icon(Icons.chevron_right, color: colorSec),
                  onTap: () =>
                      _abrirUrl('https://github.com/Sebastian-Code-0/Valtiq'),
                ),
                const Divider(height: 1, indent: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Reportar un problema'),
                  subtitle: const Text('Abre un issue en GitHub'),
                  trailing: Icon(Icons.chevron_right, color: colorSec),
                  onTap: () => _abrirUrl(
                    'https://github.com/Sebastian-Code-0/Valtiq/issues',
                  ),
                ),
              ],
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
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.acento,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Privacidad',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FilaPrivacidad(
                    icono: Icons.cloud_off,
                    texto: 'Sin conexión a internet requerida',
                    colorSec: colorSec,
                    theme: theme,
                  ),
                  _FilaPrivacidad(
                    icono: Icons.storage,
                    texto: 'Datos almacenados solo en tu dispositivo',
                    colorSec: colorSec,
                    theme: theme,
                  ),
                  _FilaPrivacidad(
                    icono: Icons.analytics_outlined,
                    texto: 'Sin telemetría ni rastreo',
                    colorSec: colorSec,
                    theme: theme,
                  ),
                  _FilaPrivacidad(
                    icono: Icons.block,
                    texto: 'Sin publicidad',
                    colorSec: colorSec,
                    theme: theme,
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

class _FilaPrivacidad extends StatelessWidget {
  const _FilaPrivacidad({
    required this.icono,
    required this.texto,
    required this.colorSec,
    required this.theme,
  });

  final IconData icono;
  final String texto;
  final Color colorSec;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icono, size: 16, color: AppColors.positivo),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(texto, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
