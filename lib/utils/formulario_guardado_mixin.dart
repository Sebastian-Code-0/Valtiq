import 'package:flutter/material.dart';

import 'error_messages.dart';

mixin FormularioGuardadoMixin<T extends StatefulWidget> on State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool guardando = false;

  Future<void> ejecutarGuardado(Future<void> Function() persistir) async {
    if (!formKey.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      await persistir();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => guardando = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajeAmigableGuardado(e))));
      }
    }
  }
}
