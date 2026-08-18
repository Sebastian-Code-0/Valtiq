import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../db/database.dart';
import '../../theme/theme.dart';
import '../../utils/categoria_gasto.dart';
import '../../utils/currency_input.dart';
import '../../utils/format.dart';

class PresupuestosScreen extends StatefulWidget {
  const PresupuestosScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<PresupuestosScreen> createState() => _PresupuestosScreenState();
}

class _PresupuestosScreenState extends State<PresupuestosScreen> {
  PresupuestosCategoria? _presupuestoPara(
    List<PresupuestosCategoria> lista,
    CategoriaGasto categoria,
  ) {
    for (final p in lista) {
      if (p.categoria == categoria.nombre) return p;
    }
    return null;
  }

  Future<void> _editarPresupuesto(
    CategoriaGasto categoria,
    PresupuestosCategoria? actual,
  ) async {
    final controller = TextEditingController(
      text: actual != null ? formatCOPInput(actual.limiteMensual) : '',
    );
    final formKey = GlobalKey<FormState>();

    final resultado = await showDialog<Object?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Límite para ${categoria.nombre}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Límite mensual',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CopInputFormatter(),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              final n = parseCOP(v);
              if (n == null || n <= 0) return 'Debe ser mayor a 0';
              return null;
            },
          ),
        ),
        actions: [
          if (actual != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'quitar'),
              child: const Text(
                'Quitar límite',
                style: TextStyle(color: AppColors.alerta),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx, parseCOP(controller.text));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (resultado == 'quitar' && actual != null) {
      await widget.db.presupuestosCategoriasDao.eliminarPresupuesto(actual.id);
    } else if (resultado is double) {
      await widget.db.presupuestosCategoriasDao.upsertPresupuesto(
        PresupuestosCategoriasCompanion(
          categoria: Value(categoria.nombre),
          limiteMensual: Value(resultado),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos por categoría')),
      body: StreamBuilder<List<PresupuestosCategoria>>(
        stream: widget.db.presupuestosCategoriasDao.watchPresupuestos(),
        builder: (context, snapshot) {
          final lista = snapshot.data ?? const [];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              for (final categoria in CategoriaGasto.values) ...[
                Card(
                  child: ListTile(
                    leading: Icon(categoria.icono, color: categoria.color),
                    title: Text(categoria.nombre),
                    subtitle: Text(
                      switch (_presupuestoPara(lista, categoria)) {
                        final p? => formatCOP(p.limiteMensual),
                        null => 'Sin límite',
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editarPresupuesto(
                      categoria,
                      _presupuestoPara(lista, categoria),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}
