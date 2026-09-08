import 'package:flutter/material.dart';

import '../../services/interes_calculator.dart';
import '../../theme/theme.dart';

/// Guía rápida de "cómo funciona Valtiq por dentro" — pensada para alguien
/// que nunca va a leer el código ni el repositorio de GitHub. Responde en
/// lenguaje simple las preguntas que un usuario se haría al ver un número
/// que no esperaba (ej. "¿por qué el interés no coincide con lo que
/// calculé a mano?").
class ComoFuncionaScreen extends StatelessWidget {
  const ComoFuncionaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;

    return Scaffold(
      appBar: AppBar(title: const Text('Cómo funciona Valtiq')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Respuestas simples a las dudas más comunes sobre cómo Valtiq '
            'calcula tus números.',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorSec),
          ),
          const SizedBox(height: AppSpacing.md),
          _TemaAyuda(
            icono: Icons.percent,
            titulo: '¿Cómo se calcula el interés?',
            cuerpo: [
              const _Parrafo(
                'Cada mes completo que pasa se suma el porcentaje de interés '
                'que pactaste, sobre el capital. Si el tiempo no es un '
                'número exacto de meses, los días sueltos se cuentan aparte, '
                'como una fracción de mes.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _Parrafo(
                'Para esos días sueltos, Valtiq siempre asume que un mes '
                'tiene ${InteresCalculator.diasPorMesConvencion} días — sin '
                'importar si el mes real tuvo 28, 29, 30 o 31. Por ejemplo, '
                '6 días se cuentan como 6 ÷ ${InteresCalculator.diasPorMesConvencion} '
                '= 0,2 meses de interés, sin importar en qué mes hayan caído '
                'esos días.',
                colorSec: colorSec,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Ejemplo(
                titulo: 'Ejemplo',
                lineas: const [
                  'Debes \$1.000.000 al 2% mensual.',
                  'Han pasado 8 meses y 6 días.',
                  'Interés = \$1.000.000 × 2% × 8,2 meses = \$164.000',
                ],
                theme: theme,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Parrafo(
                'Puedes ver este mismo desglose, con tus propios números, '
                'tocando "¿Cómo se calculó?" dentro de cualquier deuda o '
                'préstamo que tenga interés.',
                colorSec: colorSec,
                enfasis: true,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.swap_horiz,
            titulo: '¿Qué diferencia hay entre interés simple y compuesto?',
            cuerpo: [
              _Parrafo(
                'Simple: el interés de cada mes se calcula siempre sobre el '
                'mismo capital inicial. Es una suma que crece siempre al '
                'mismo ritmo.',
                colorSec: colorSec,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Parrafo(
                'Compuesto: el interés generado se suma al capital antes de '
                'calcular el interés del mes siguiente — "interés sobre '
                'interés". Por eso crece un poco más rápido que el simple '
                'con el paso del tiempo.',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.account_balance_outlined,
            titulo: '¿Qué significa "saldo original" y "saldo insoluto"?',
            cuerpo: [
              _Parrafo(
                'Saldo original: el interés se calcula siempre sobre el '
                'monto que prestaste al inicio, sin importar cuánto se haya '
                'abonado. Es la forma más simple, pensada para deuda '
                'informal entre conocidos.',
                colorSec: colorSec,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Parrafo(
                'Saldo insoluto: cada vez que se registra un abono, el '
                'interés de ahí en adelante se calcula sobre lo que aún se '
                'debe, no sobre el monto original. Así funciona un crédito '
                'bancario real — por eso pagar antes siempre te ahorra más '
                'interés en esta modalidad.',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.compare_arrows,
            titulo: '¿Cuál es la diferencia entre una Deuda y un Préstamo?',
            cuerpo: [
              _Parrafo(
                'Una Deuda es dinero que TÚ debes a alguien más. Un '
                'Préstamo es dinero que a TI te deben. El cálculo de '
                'interés es exactamente el mismo en los dos casos — lo '
                'único que cambia es de qué lado estás.',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.payments_outlined,
            titulo: '¿Cómo se suman los ingresos variables al mes?',
            cuerpo: [
              _Parrafo(
                'Cada ingreso tiene una frecuencia, y Valtiq la usa para '
                'saber cuánto representa "por mes":',
                colorSec: colorSec,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Bullet('Mensual: se cuenta tal cual, sin cambios.'),
              _Bullet(
                'Quincenal: se multiplica por 2, porque un mes tiene dos '
                'quincenas.',
              ),
              _Bullet(
                'Semanal: se multiplica por 52 ÷ 12 (≈ 4,33), porque un mes '
                'no tiene exactamente 4 semanas completas.',
              ),
              _Bullet(
                'Único: solo cuenta en el mes de su propia fecha — no se '
                'repite ni se suma en los meses siguientes.',
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.receipt_long_outlined,
            titulo: '¿Por qué mis gastos fijos aparecen "mensualizados"?',
            cuerpo: [
              _Parrafo(
                'Un gasto fijo (arriendo, gimnasio, una suscripción) puede '
                'ser mensual, quincenal o semanal. Para que el resumen del '
                'mes sea comparable, Valtiq convierte todos a lo que '
                'representan "por mes", con la misma regla que usa para los '
                'ingresos variables (×2 quincenal, ×52/12 semanal).',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.notifications_active_outlined,
            titulo: '¿Cómo funcionan los recordatorios?',
            cuerpo: [
              _Parrafo(
                'Un recordatorio empieza a avisar cuando faltan los días '
                'que configuraste para la fecha límite. Puede avisar "una '
                'sola vez" durante toda esa ventana, o "todos los días" '
                'hasta que marques la deuda, préstamo o gasto como pagado.',
                colorSec: colorSec,
              ),
              const SizedBox(height: AppSpacing.sm),
              _Parrafo(
                'Si marcas el registro relacionado como pagado (o lo '
                'eliminas), el recordatorio se desactiva solo — no hace '
                'falta apagarlo a mano.',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.lock_outline,
            titulo: '¿Qué hace el bloqueo con PIN o biometría?',
            cuerpo: [
              _Parrafo(
                'Si lo activas en Ajustes → Seguridad, Valtiq te pedirá tu '
                'PIN o huella/rostro cada vez que abras la app. Es una '
                'segunda puerta local: no reemplaza el bloqueo del propio '
                'celular, solo evita que alguien con tu celular desbloqueado '
                'entre directo a tus finanzas.',
                colorSec: colorSec,
              ),
            ],
          ),
          _TemaAyuda(
            icono: Icons.storage_outlined,
            titulo: '¿Dónde se guardan mis datos?',
            cuerpo: [
              _Parrafo(
                'Todo lo que registras se queda únicamente en tu celular — '
                'Valtiq no usa internet ni nube, y nadie más que tú puede '
                'ver esta información. Puedes hacer una copia de seguridad '
                'manual desde Ajustes → Copia de seguridad, por ejemplo '
                'antes de cambiar de celular.',
                colorSec: colorSec,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemaAyuda extends StatelessWidget {
  const _TemaAyuda({
    required this.icono,
    required this.titulo,
    required this.cuerpo,
  });

  final IconData icono;
  final String titulo;
  final List<Widget> cuerpo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icono, color: theme.colorScheme.primary),
            title: Text(
              titulo,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: cuerpo,
          ),
        ),
      ),
    );
  }
}

class _Parrafo extends StatelessWidget {
  const _Parrafo(this.texto, {this.colorSec, this.enfasis = false});

  final String texto;
  final Color? colorSec;
  final bool enfasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      texto,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: enfasis ? theme.colorScheme.primary : colorSec,
        fontStyle: enfasis ? FontStyle.italic : null,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: theme.textTheme.bodyMedium),
          Expanded(child: Text(texto, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Ejemplo extends StatelessWidget {
  const _Ejemplo({
    required this.titulo,
    required this.lineas,
    required this.theme,
  });

  final String titulo;
  final List<String> lineas;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (final linea in lineas)
            Text(linea, style: monoStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
