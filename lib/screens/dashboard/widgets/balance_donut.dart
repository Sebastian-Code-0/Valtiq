import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../utils/format.dart';

/// Donut de composición del balance mensual: gastos fijos, gastos variables
/// y disponible como fracciones de ingresos. Si gastos + variables superan
/// los ingresos, se reescalan entre sí para llenar el anillo completo (sin
/// porción de "disponible"), evitando arcos que se solapen más allá de 360°.
class BalanceDonut extends StatelessWidget {
  const BalanceDonut({
    super.key,
    required this.ingresos,
    required this.gastos,
    required this.gastosVariables,
    required this.disponible,
    required this.disponibleColor,
    this.diametro = 100.0,
  });

  final double ingresos;
  final double gastos;
  final double gastosVariables;
  final double disponible;
  final Color disponibleColor;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ingresos <= 0) {
      return SizedBox(
        width: diametro,
        height: diametro,
        child: Center(
          child: Icon(
            Icons.donut_large_outlined,
            size: 32,
            color: theme.colorSecundario,
          ),
        ),
      );
    }

    final gastosTotal = gastos + gastosVariables;
    double fraccionGastos;
    double fraccionVariables;
    double fraccionDisponible;
    if (gastosTotal >= ingresos) {
      fraccionGastos = gastosTotal <= 0 ? 0.0 : gastos / gastosTotal;
      fraccionVariables = gastosTotal <= 0
          ? 0.0
          : gastosVariables / gastosTotal;
      fraccionDisponible = 0.0;
    } else {
      fraccionGastos = gastos / ingresos;
      fraccionVariables = gastosVariables / ingresos;
      fraccionDisponible = disponible / ingresos;
    }

    final texto = formatCOP(disponible);
    final painter = TextPainter(
      text: TextSpan(
        text: texto,
        style: monoStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final diametroInterior = diametro - 24 - AppSpacing.sm;
    final cabeAdentro = painter.width <= diametroInterior * 0.78;

    final anillo = SizedBox(
      width: diametro,
      height: diametro,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, progreso, child) => CustomPaint(
              size: Size(diametro, diametro),
              painter: _BalanceDonutPainter(
                fraccionGastos: fraccionGastos,
                fraccionVariables: fraccionVariables,
                fraccionDisponible: fraccionDisponible,
                colorGastos: AppColors.alerta,
                colorVariables: AppColors.alerta.withValues(alpha: 0.35),
                colorDisponible: disponibleColor,
                colorPista: theme.dividerColor,
                progreso: progreso,
                relleno: !cabeAdentro,
              ),
            ),
          ),
          if (cabeAdentro)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  texto,
                  style: monoStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: disponibleColor,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
        ],
      ),
    );

    if (cabeAdentro) return anillo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        anillo,
        const SizedBox(height: AppSpacing.xs),
        Text(
          texto,
          style: monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: disponibleColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BalanceDonutPainter extends CustomPainter {
  _BalanceDonutPainter({
    required this.fraccionGastos,
    required this.fraccionVariables,
    required this.fraccionDisponible,
    required this.colorGastos,
    required this.colorVariables,
    required this.colorDisponible,
    required this.colorPista,
    required this.progreso,
    required this.relleno,
  });

  final double fraccionGastos;
  final double fraccionVariables;
  final double fraccionDisponible;
  final Color colorGastos;
  final Color colorVariables;
  final Color colorDisponible;
  final Color colorPista;
  final double progreso;
  final bool relleno;

  static const _grosor = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = relleno
        ? size.shortestSide / 2
        : (size.shortestSide - _grosor) / 2;
    final arcoRect = Rect.fromCircle(center: centro, radius: radio);
    final estilo = relleno ? PaintingStyle.fill : PaintingStyle.stroke;

    final pistaPaint = Paint()
      ..color = colorPista
      ..style = estilo
      ..strokeWidth = _grosor
      ..isAntiAlias = true;
    canvas.drawCircle(centro, radio, pistaPaint);

    var anguloActual = -math.pi / 2;

    void dibujarArco(double fraccion, Color color) {
      final barrido = 2 * math.pi * fraccion * progreso;
      if (barrido > 0) {
        final paint = Paint()
          ..color = color
          ..style = estilo
          ..strokeWidth = _grosor
          ..isAntiAlias = true;
        // Solape leve para que segmentos consecutivos se toquen de más en
        // vez de dejar una línea/gap visible entre colores.
        const solape = 0.025;
        canvas.drawArc(
          arcoRect,
          anguloActual,
          barrido + solape,
          relleno,
          paint,
        );
      }
      anguloActual += 2 * math.pi * fraccion;
    }

    dibujarArco(fraccionGastos, colorGastos);
    dibujarArco(fraccionVariables, colorVariables);
    dibujarArco(fraccionDisponible, colorDisponible);
  }

  @override
  bool shouldRepaint(covariant _BalanceDonutPainter oldDelegate) {
    return oldDelegate.fraccionGastos != fraccionGastos ||
        oldDelegate.fraccionVariables != fraccionVariables ||
        oldDelegate.fraccionDisponible != fraccionDisponible ||
        oldDelegate.colorDisponible != colorDisponible ||
        oldDelegate.progreso != progreso ||
        oldDelegate.relleno != relleno;
  }
}
