import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'categoria_gasto.dart';
import 'date_format.dart';
import 'format.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.acento.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.acento),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
    this.onClear,
    this.placeholder = 'Sin fecha',
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;
    final tieneFecha = value != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor, width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorSec),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tieneFecha ? formatFechaLegible(value!) : placeholder,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: tieneFecha
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: tieneFecha ? null : colorSec,
                    ),
                  ),
                ],
              ),
            ),
            if (tieneFecha && onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClear,
                tooltip: 'Quitar fecha',
                visualDensity: VisualDensity.compact,
              )
            else
              Icon(Icons.chevron_right, color: colorSec),
          ],
        ),
      ),
    );
  }
}

class FormSaveButton extends StatelessWidget {
  const FormSaveButton({
    super.key,
    required this.onPressed,
    required this.loading,
    this.label = 'Guardar',
    this.icon = Icons.check_circle,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(loading ? 'Guardando...' : label),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.valor,
    required this.colorSec,
    required this.theme,
  });

  final String label;
  final String valor;
  final Color colorSec;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.labelColumnWidth,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
            ),
          ),
          Expanded(child: Text(valor, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

const _nombresMeses = [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

class SelectorMes extends StatelessWidget {
  const SelectorMes({
    super.key,
    required this.anio,
    required this.mes,
    required this.onCambiar,
    this.compacto = false,
    this.mesExcluido,
  });

  final int anio;
  final int mes;
  final ValueChanged<DateTime> onCambiar;
  final bool compacto;
  // Mes que este selector no puede alcanzar (p. ej. el mes que ya muestra el
  // otro selector en un comparativo), para que ambos nunca coincidan.
  final DateTime? mesExcluido;

  static String nombreMes(int mes) => _nombresMeses[mes - 1];
  static String nombreMesCorto(int mes) =>
      _nombresMeses[mes - 1].substring(0, 3);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ahora = DateTime.now();
    final esMesActual = anio == ahora.year && mes == ahora.month;
    final mesAnterior = DateTime(anio, mes - 1, 1);
    final mesSiguiente = DateTime(anio, mes + 1, 1);
    final anteriorExcluido = mesExcluido != null && mesAnterior == mesExcluido;
    final siguienteExcluido =
        mesExcluido != null && mesSiguiente == mesExcluido;
    final estiloTexto = compacto
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final densidad = compacto ? VisualDensity.compact : null;
    // Pantallas angostas (celular) no tienen espacio para "Julio 2026" x2
    // lado a lado en el comparativo del Dashboard sin desbordar; ahí se
    // abrevia a "Jul 26". En pantallas anchas (tablet/desktop) se mantiene
    // el nombre completo.
    final esPantallaAngosta = MediaQuery.sizeOf(context).width < 600;
    final textoMes = esPantallaAngosta
        ? '${nombreMesCorto(mes)} ${(anio % 100).toString().padLeft(2, '0')}'
        : '${_nombresMeses[mes - 1]} $anio';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          visualDensity: densidad,
          tooltip: 'Mes anterior',
          onPressed: anteriorExcluido ? null : () => onCambiar(mesAnterior),
        ),
        Text(textoMes, style: estiloTexto),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          visualDensity: densidad,
          tooltip: 'Mes siguiente',
          onPressed: esMesActual || siguienteExcluido
              ? null
              : () => onCambiar(mesSiguiente),
        ),
      ],
    );
  }
}

class BarraCategoria extends StatelessWidget {
  const BarraCategoria({
    super.key,
    required this.categoria,
    required this.monto,
    required this.montoMaximo,
  });

  final String categoria;
  final double monto;
  final double montoMaximo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoriaGasto.colorPara(categoria);
    final fraccion = montoMaximo <= 0
        ? 0.0
        : (monto / montoMaximo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(CategoriaGasto.iconoPara(categoria), size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 96,
            child: Text(
              categoria,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _PistaBarra(color: color, fraccion: fraccion),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatCOP(monto),
            style: monoStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Pista de una barra proporcional: fondo tenue del [color] + relleno
/// (opacidad [alpha]) con ancho `fraccion` del total. Compartida por
/// [BarraCategoria] y [BarraCategoriaComparada].
class _PistaBarra extends StatelessWidget {
  const _PistaBarra({
    required this.color,
    required this.fraccion,
    this.alpha = 1.0,
  });

  final Color color;
  final double fraccion;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final colorRelleno = alpha == 1.0 ? color : color.withValues(alpha: alpha);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 8,
        color: color.withValues(alpha: 0.15),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraccion),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, valor, child) => FractionallySizedBox(
            widthFactor: valor,
            child: Container(color: colorRelleno),
          ),
        ),
      ),
    );
  }
}

class BarraProgreso extends StatelessWidget {
  const BarraProgreso({
    super.key,
    required this.fraccion,
    required this.color,
  });

  /// 0.0 a 1.0 — la fracción ya calculada por quien llama.
  final double fraccion;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final valor = fraccion.isFinite ? fraccion.clamp(0.0, 1.0) : 0.0;
    return _PistaBarra(color: color, fraccion: valor);
  }
}

class BarraCategoriaComparada extends StatelessWidget {
  const BarraCategoriaComparada({
    super.key,
    required this.categoria,
    required this.mesACorto,
    required this.montoA,
    required this.mesBCorto,
    required this.montoB,
    required this.montoMaximo,
  });

  final String categoria;
  final String mesACorto;
  final double montoA;
  final String mesBCorto;
  final double montoB;
  final double montoMaximo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = CategoriaGasto.colorPara(categoria);
    final fraccionA = montoMaximo <= 0
        ? 0.0
        : (montoA / montoMaximo).clamp(0.0, 1.0);
    final fraccionB = montoMaximo <= 0
        ? 0.0
        : (montoB / montoMaximo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(CategoriaGasto.iconoPara(categoria), size: 16, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  categoria,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _InsigniaVariacion(montoA: montoA, montoB: montoB),
            ],
          ),
          const SizedBox(height: 4),
          _MiniFilaMes(
            label: mesACorto,
            monto: montoA,
            color: color,
            fraccion: fraccionA,
            alpha: 0.35,
          ),
          const SizedBox(height: 2),
          _MiniFilaMes(
            label: mesBCorto,
            monto: montoB,
            color: color,
            fraccion: fraccionB,
          ),
        ],
      ),
    );
  }
}

class _MiniFilaMes extends StatelessWidget {
  const _MiniFilaMes({
    required this.label,
    required this.monto,
    required this.color,
    required this.fraccion,
    this.alpha = 1.0,
  });

  final String label;
  final double monto;
  final Color color;
  final double fraccion;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorSecundario,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PistaBarra(color: color, fraccion: fraccion, alpha: alpha),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 76,
          child: Text(
            formatCOP(monto),
            style: monoStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Insignia de variación entre [montoA] y [montoB]. Muestra "nuevo" si la
/// categoría no existía en el mes A, nada si la variación es 0%, un
/// porcentaje normal hasta +300% (o cualquier baja), y un multiplicador
/// (ej. "×20") por encima de +300%, donde un porcentaje ya no es legible.
/// Una baja nunca se muestra como "100%" salvo eliminación real a $0
/// (evita que el redondeo diga "eliminado" cuando queda remanente).
class _InsigniaVariacion extends StatelessWidget {
  const _InsigniaVariacion({required this.montoA, required this.montoB});

  final double montoA;
  final double montoB;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (montoA == 0 && montoB > 0) {
      return Text(
        'nuevo',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorSecundario,
        ),
      );
    }
    if (montoA <= 0) return const SizedBox.shrink();

    final pct = ((montoB - montoA) / montoA * 100).round();
    if (pct == 0) return const SizedBox.shrink();

    final esMas = pct > 0;

    if (esMas && pct > 300) {
      final multiplicador = (montoB / montoA).round();
      return Text(
        '↑ ×$multiplicador',
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.alerta,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // El redondeo puede inflar una baja de, por ej., 99.9% a "100%" cuando
    // en realidad queda un remanente (montoB > 0). "100%" debe reservarse
    // para cuando la categoría se elimina por completo.
    var pctMostrado = pct.abs();
    if (!esMas && pctMostrado >= 100 && montoB > 0) {
      pctMostrado = 99;
    }

    return Text(
      '${esMas ? '↑' : '↓'} $pctMostrado%',
      style: theme.textTheme.bodySmall?.copyWith(
        color: esMas ? AppColors.alerta : AppColors.positivo,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorSec = isDark
        ? AppColors.textoSecundarioOscuro
        : AppColors.textoSecundarioClaro;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: colorSec),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorSec,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
