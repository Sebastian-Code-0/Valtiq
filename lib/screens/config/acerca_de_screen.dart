import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/theme.dart';
import 'ajustes_widgets.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  Future<void> _abrirUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    Widget enlace(IconData icono, String titulo, String sub, String url) =>
        FilaAjuste(
          icono: icono,
          titulo: titulo,
          subtitulo: sub,
          trailing: Icon(Icons.open_in_new, size: 18, color: colorSec),
          onTap: () => _abrirUrl(url),
        );

    return PaginaAjustes(
      titulo: 'Acerca de',
      children: [
        // Logo y versión sueltos, sin tarjeta.
        const SizedBox(height: AppSpacing.md),
        Image.asset(
          'assets/logo_icono.png',
          height: 64,
          color: theme.colorScheme.primary,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Valtiq',
          textAlign: TextAlign.center,
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
              textAlign: TextAlign.center,
              style: monoStyle(fontSize: 13, color: colorSec),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Gestión de préstamos, deudas e ingresos personales. '
          'Tus datos se almacenan localmente, sin nube.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorSec),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        TarjetaFilas(
          children: [
            enlace(
              Icons.gavel_outlined,
              'Licencia',
              'GNU General Public License v3.0',
              'https://www.gnu.org/licenses/gpl-3.0.html',
            ),
            enlace(
              Icons.code,
              'Código fuente',
              'github.com/Sebastian-Code-0/Valtiq',
              'https://github.com/Sebastian-Code-0/Valtiq',
            ),
            enlace(
              Icons.bug_report_outlined,
              'Reportar un problema',
              'Abre un issue en GitHub',
              'https://github.com/Sebastian-Code-0/Valtiq/issues',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const TarjetaFilas(
          titulo: 'Privacidad',
          children: [
            _FilaPrivacidad(
              icono: Icons.cloud_off,
              texto: 'Sin conexión a internet requerida',
            ),
            _FilaPrivacidad(
              icono: Icons.storage,
              texto: 'Datos almacenados solo en tu dispositivo',
            ),
            _FilaPrivacidad(
              icono: Icons.analytics_outlined,
              texto: 'Sin telemetría ni rastreo',
            ),
            _FilaPrivacidad(icono: Icons.block, texto: 'Sin publicidad'),
          ],
        ),
      ],
    );
  }
}

class _FilaPrivacidad extends StatelessWidget {
  const _FilaPrivacidad({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      child: Row(
        children: [
          Icon(icono, size: 18, color: context.colores.textoSecundario),
          const SizedBox(width: 14),
          Flexible(child: Text(texto, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
