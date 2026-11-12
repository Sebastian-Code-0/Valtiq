import 'package:flutter/material.dart';

import '../services/interes_calculator.dart';
import '../theme/theme.dart';
import 'categoria_gasto.dart';
import 'date_format.dart';
import 'encabezado_pantalla.dart';
import 'format.dart';

/// Página de un formulario (crear o editar): flecha para volver, título
/// grande y, debajo, las secciones en una columna centrada que no se estira
/// de más en pantallas anchas.
class PaginaFormulario extends StatelessWidget {
  const PaginaFormulario({
    super.key,
    required this.formKey,
    required this.titulo,
    required this.children,
    this.kicker,
  });

  final GlobalKey<FormState> formKey;
  final String titulo;
  final String? kicker;
  final List<Widget> children;

  /// Ancho máximo de la columna del formulario.
  static const anchoMaximo = 760.0;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 48),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              ancho ? AppSpacing.lg : AppSpacing.md,
              AppSpacing.sm,
              ancho ? AppSpacing.lg : AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: anchoMaximo),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EncabezadoPantalla(titulo: titulo, kicker: kicker),
                    SizedBox(height: ancho ? AppSpacing.lg : AppSpacing.md),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sección de un formulario: una tarjeta con su título y los campos.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  final String title;

  /// Ya no se dibuja (el diseño nuevo lleva solo el título); se conserva
  /// para no tocar cada formulario.
  final IconData icon;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ancho = MediaQuery.sizeOf(context).width >= 600;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
            padding ?? EdgeInsets.all(ancho ? AppSpacing.lg : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Un campo con su nombre ENCIMA (en vez de dentro del campo) y, si hace
/// falta, una explicación corta debajo.
class CampoEtiquetado extends StatelessWidget {
  const CampoEtiquetado({
    super.key,
    required this.etiqueta,
    required this.child,
    this.ayuda,
    this.error,
  });

  final String etiqueta;
  final Widget child;
  final String? ayuda;

  /// Mensaje en rojo debajo del campo (para lo que no es un campo de texto,
  /// que ya muestra su propio error).
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorSec = context.colores.textoSecundario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          etiqueta,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: colorSec,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.colores.alerta,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (ayuda != null) ...[
          const SizedBox(height: 6),
          Text(
            ayuda!,
            style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
          ),
        ],
      ],
    );
  }
}

/// Dos (o más) campos lado a lado si hay ancho; uno debajo del otro en
/// celular.
class FilaCampos extends StatelessWidget {
  const FilaCampos({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, h) in children.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                h,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, h) in children.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: h),
            ],
          ],
        );
      },
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
    this.mostrarEtiqueta = true,
  });

  final String label;
  final IconData icon;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String placeholder;

  /// `false` cuando el nombre ya va encima (dentro de un [CampoEtiquetado]).
  final bool mostrarEtiqueta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colores;
    final colorSec = c.textoSecundario;
    final tieneFecha = value != null;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusCampo),
      side: BorderSide(color: c.divisor, width: AppSpacing.borde),
    );

    return Material(
      color: c.relieve,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorSec),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (mostrarEtiqueta) ...[
                        Text(
                          label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorSec,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
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
    final boton = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(180, 48),
        textStyle: const TextStyle(
          fontFamily: fuenteTexto,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(context.colores.texto),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(loading ? 'Guardando...' : label),
        ],
      ),
    );
    // En celular ocupa todo el ancho; en pantallas anchas es una píldora a
    // la izquierda, del tamaño de su texto.
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 480
          ? SizedBox(width: double.infinity, child: boton)
          : Align(alignment: Alignment.centerLeft, child: boton),
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

String _fmtDecimal(double v) {
  if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Tarjeta expandible "¿Cómo se calculó?" — desglosa el interés acumulado
/// tramo por tramo (uno solo en modalidad `saldo_original`, uno por cada
/// abono en `saldo_insoluto`) mostrando la misma fórmula y convención de 30
/// días/mes que usa [InteresCalculator], para que el usuario pueda auditar
/// el número en vez de solo confiar en él. No se muestra si [tramos] está
/// vacío (sin interés o sin tiempo transcurrido todavía).
class InteresDesgloseCard extends StatelessWidget {
  const InteresDesgloseCard({
    super.key,
    required this.tramos,
    required this.modalidadCalculo,
  });

  final List<TramoInteres> tramos;
  final String modalidadCalculo;

  @override
  Widget build(BuildContext context) {
    if (tramos.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorSec = theme.colorSecundario;
    final interesTotal = tramos.fold<int>(0, (s, t) => s + t.interes);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.calculate_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            '¿Cómo se calculó?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: [
            for (var i = 0; i < tramos.length; i++) ...[
              if (i > 0) const Divider(height: AppSpacing.lg),
              _TramoDetalle(
                tramo: tramos[i],
                modalidadCalculo: modalidadCalculo,
                colorSec: colorSec,
                theme: theme,
              ),
            ],
            if (tramos.length > 1) ...[
              const Divider(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Interés total:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorSec,
                    ),
                  ),
                  Text(
                    formatCOP(interesTotal),
                    style: monoStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TramoDetalle extends StatelessWidget {
  const _TramoDetalle({
    required this.tramo,
    required this.modalidadCalculo,
    required this.colorSec,
    required this.theme,
  });

  final TramoInteres tramo;
  final String modalidadCalculo;
  final Color colorSec;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final tasaTxt = formatTasaInicial(tramo.tasaMensualPct);
    final mesesTxt = _fmtDecimal(tramo.mesesTotal);
    final formula = modalidadCalculo == 'compuesto'
        ? '${formatCOP(tramo.capitalBase)} × [(1 + $tasaTxt%) ^ $mesesTxt − 1]'
        : '${formatCOP(tramo.capitalBase)} × $tasaTxt% × $mesesTxt meses';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Del ${formatFecha(tramo.fechaInicio)} al ${formatFecha(tramo.fechaFin)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorSec,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(formula, style: monoStyle(fontSize: 13)),
        const SizedBox(height: 2),
        Text(
          '${tramo.mesesCompletos} ${tramo.mesesCompletos == 1 ? 'mes completo' : 'meses completos'}'
          '${tramo.diasParciales > 0 ? ' + ${tramo.diasParciales} días' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
        ),
        if (tramo.diasParciales > 0)
          Text(
            '${tramo.diasParciales} días ÷ ${InteresCalculator.diasPorMesConvencion} = '
            '${_fmtDecimal(tramo.diasParciales / InteresCalculator.diasPorMesConvencion)} meses',
            style: theme.textTheme.bodySmall?.copyWith(color: colorSec),
          ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '= ${formatCOP(tramo.interes)}',
            style: monoStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
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
    this.colorOverride,
    this.respetarOcultar = false,
  });

  /// Si es true, el monto se oculta cuando "Ocultar montos" está activo
  /// (lo usa Inicio; en Finanzas los montos siempre se ven).
  final bool respetarOcultar;

  final String categoria;
  final double monto;
  final double montoMaximo;
  final Color? colorOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = colorOverride ?? CategoriaGasto.colorPara(categoria);
    final fraccion = montoMaximo <= 0
        ? 0.0
        : (monto / montoMaximo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
              // El monto va anclado al borde DERECHO (encima del final de
              // la barra) y crece hacia la izquierda. Originalmente había un
              // Spacer + Flexible: cada uno tomaba la mitad del espacio y el
              // monto arrancaba en el centro de la pantalla, flotando lejos
              // de ambos bordes en pantallas anchas. Si no cabe (celular
              // angosto + monto enorme) se encoge en vez de cortarse.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    respetarOcultar ? formatMonto(monto) : formatCOP(monto),
                    style: monoStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _PistaBarra(color: color, fraccion: fraccion),
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
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: context.colores.relieve,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: fraccion),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, valor, child) => FractionallySizedBox(
            widthFactor: valor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorRelleno,
                borderRadius: BorderRadius.circular(3),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class BarraProgreso extends StatelessWidget {
  const BarraProgreso({super.key, required this.fraccion, required this.color});

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
            // Solo se usa en Inicio: respeta "Ocultar montos".
            formatMonto(monto),
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
          color: context.colores.alerta,
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
        color: esMas ? context.colores.alerta : context.colores.positivo,
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
    final colorSec = context.colores.textoSecundario;
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
              activeColor: context.colores.sobreAcento,
              activeTrackColor: context.colores.acentoRelleno,
            ),
          ],
        ),
      ),
    );
  }
}
