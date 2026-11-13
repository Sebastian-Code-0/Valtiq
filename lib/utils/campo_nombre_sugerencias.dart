import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'nombres_conocidos.dart';

/// Campo de nombre que, al escribir, sugiere nombres conocidos (bancos,
/// tiendas, billeteras…; ver `nombres_conocidos.dart`). Las sugerencias son
/// solo texto: elegir una completa el nombre y avisa con [alElegir] (por
/// ejemplo, para poner el tipo de deuda que le corresponde).
class CampoNombreConSugerencias extends StatefulWidget {
  const CampoNombreConSugerencias({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.validator,
    this.alElegir,
    this.grupos,
  });

  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final ValueChanged<Sugerencia>? alElegir;

  /// Qué grupos de la lista sugerir (null = todos). En gastos no salen
  /// bancos ni financieras: ver `esGrupoDeGasto`.
  final bool Function(GrupoNombres)? grupos;

  @override
  State<CampoNombreConSugerencias> createState() =>
      _CampoNombreConSugerenciasState();
}

class _CampoNombreConSugerenciasState extends State<CampoNombreConSugerencias> {
  final _foco = FocusNode();

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return RawAutocomplete<Sugerencia>(
      textEditingController: widget.controller,
      focusNode: _foco,
      displayStringForOption: (s) => s.nombre,
      optionsBuilder: (valor) =>
          sugerirNombres(valor.text, limite: 6, grupos: widget.grupos),
      onSelected: (s) => widget.alElegir?.call(s),
      fieldViewBuilder: (context, controller, foco, alEnviar) => TextFormField(
        controller: controller,
        focusNode: foco,
        textCapitalization: TextCapitalization.sentences,
        decoration: widget.decoration,
        validator: widget.validator,
        onFieldSubmitted: (_) => alEnviar(),
      ),
      optionsViewBuilder: (context, elegir, opciones) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Material(
            color: c.superficie,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusRecuadro),
              side: BorderSide(color: c.divisor, width: AppSpacing.borde),
            ),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 360),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                children: [
                  for (final s in opciones)
                    InkWell(
                      onTap: () => elegir(s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              s.grupo.tipoDeuda.icono,
                              size: 18,
                              color: c.textoSecundario,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.grupo.tipo,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: c.textoSecundario),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
