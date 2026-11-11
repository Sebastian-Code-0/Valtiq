import 'package:flutter/material.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import 'acerca_de_screen.dart';
import 'apariencia_screen.dart';
import 'como_funciona_screen.dart';
import 'config_smtp_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'presupuestos_screen.dart';
import 'respaldo_screen.dart';
import 'seguridad_screen.dart';

/// Marca que las pantallas de configuración se están mostrando DENTRO de
/// Ajustes (debajo del selector de secciones), no como página aparte: así
/// saben que no deben dibujar su propia barra de título.
class AjustesEmbebido extends InheritedWidget {
  const AjustesEmbebido({super.key, required super.child});

  static bool en(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AjustesEmbebido>() != null;

  @override
  bool updateShouldNotify(AjustesEmbebido oldWidget) => false;
}

/// Barra de título de una pantalla de configuración: `null` cuando va
/// dentro de Ajustes (el título ya lo da el selector), normal si se abre
/// como página suelta (por ejemplo, desde el aviso de "correo perdido").
PreferredSizeWidget? barraAjustes(BuildContext context, String titulo) =>
    AjustesEmbebido.en(context) ? null : AppBar(title: Text(titulo));

class _Seccion {
  const _Seccion(this.nombre, this.icono, this.construir);

  final String nombre;
  final IconData icono;
  final Widget Function(AppDatabase db) construir;
}

final _secciones = <_Seccion>[
  _Seccion('Perfil', Icons.person_outline, (_) => const PerfilScreen()),
  _Seccion(
    'Apariencia',
    Icons.palette_outlined,
    (_) => const AparienciaScreen(),
  ),
  _Seccion(
    'Notificaciones',
    Icons.notifications_outlined,
    (db) => NotificacionesScreen(db: db),
  ),
  _Seccion('Seguridad', Icons.lock_outline, (_) => const SeguridadScreen()),
  _Seccion(
    'Copia de seguridad',
    Icons.backup_outlined,
    (db) => RespaldoScreen(db: db),
  ),
  _Seccion(
    'Presupuestos',
    Icons.pie_chart_outline,
    (db) => PresupuestosScreen(db: db),
  ),
  _Seccion(
    'Cómo funciona',
    Icons.school_outlined,
    (_) => const ComoFuncionaScreen(),
  ),
  _Seccion('Correo', Icons.email_outlined, (db) => ConfigSmtpScreen(db: db)),
  _Seccion('Acerca de', Icons.info_outlined, (_) => const AcercaDeScreen()),
];

/// Ajustes: un selector de secciones arriba (como el de Finanzas) y, debajo,
/// la sección elegida. Ya no se abre una página nueva por cada ajuste.
///
/// - En PC va dentro del área de contenido, con el menú lateral a la vista
///   ([embebido] = true): muestra el título "Ajustes" como encabezado.
/// - En celular se abre como página desde Inicio: lleva barra con flecha
///   para volver.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.db, this.embebido = false});

  final AppDatabase db;
  final bool embebido;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _seccion = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: widget.embebido ? null : AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.embebido)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Ajustes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            _SelectorSeccion(
              seleccionada: _seccion,
              onElegir: (i) => setState(() => _seccion = i),
              margen: widget.embebido ? AppSpacing.lg : AppSpacing.md,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: AjustesEmbebido(
                // Clave por sección: al cambiar, la sección anterior se
                // desmonta y la nueva arranca limpia.
                child: KeyedSubtree(
                  key: ValueKey(_seccion),
                  child: _secciones[_seccion].construir(widget.db),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de botones tipo píldora, uno por sección. Si no caben todos (son
/// varios), la fila se desliza de lado.
class _SelectorSeccion extends StatelessWidget {
  const _SelectorSeccion({
    required this.seleccionada,
    required this.onElegir,
    required this.margen,
  });

  final int seleccionada;
  final ValueChanged<int> onElegir;
  final double margen;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final theme = Theme.of(context);
    Widget pildora(int i) {
      final elegida = i == seleccionada;
      final color = elegida ? c.sobreAcento : c.texto;
      return Semantics(
        button: true,
        selected: elegida,
        child: Material(
          color: elegida ? c.acentoRelleno : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(
              color: elegida ? c.acentoRelleno : c.divisor,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onElegir(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_secciones[i].icono, size: 18, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _secciones[i].nombre,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Con ratón no se puede arrastrar una fila para deslizarla, así que
        // en pantallas anchas (PC, tablet) las píldoras se acomodan en las
        // líneas que hagan falta. En celular van en una sola fila que se
        // desliza con el dedo, para no gastar media pantalla.
        if (constraints.maxWidth >= 600) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: margen),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _secciones.length; i++)
                  SizedBox(height: 44, child: pildora(i)),
              ],
            ),
          );
        }
        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: margen),
            itemCount: _secciones.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => pildora(i),
          ),
        );
      },
    );
  }
}
