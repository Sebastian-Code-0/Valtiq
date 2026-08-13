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
  });

  final int anio;
  final int mes;
  final ValueChanged<DateTime> onCambiar;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ahora = DateTime.now();
    final esMesActual = anio == ahora.year && mes == ahora.month;
    final estiloTexto = compacto
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final densidad = compacto ? VisualDensity.compact : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          visualDensity: densidad,
          tooltip: 'Mes anterior',
          onPressed: () => onCambiar(DateTime(anio, mes - 1, 1)),
        ),
        Text('${_nombresMeses[mes - 1]} $anio', style: estiloTexto),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          visualDensity: densidad,
          tooltip: 'Mes siguiente',
          onPressed: esMesActual
              ? null
              : () => onCambiar(DateTime(anio, mes + 1, 1)),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 8,
                color: color.withValues(alpha: 0.15),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraccion,
                  child: Container(color: color),
                ),
              ),
            ),
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
