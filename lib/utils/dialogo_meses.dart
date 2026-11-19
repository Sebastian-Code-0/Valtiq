import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pregunta en cuántos meses se quiere terminar de pagar (calculadoras de
/// cuota de Deudas y Préstamos). Devuelve el número o `null`.
class DialogoMeses extends StatefulWidget {
  const DialogoMeses({super.key});

  @override
  State<DialogoMeses> createState() => _DialogoMesesState();
}

class _DialogoMesesState extends State<DialogoMeses> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calcular la cuota'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: const InputDecoration(
          labelText: '¿En cuántos meses quieres terminar?',
        ),
        onSubmitted: (_) => Navigator.pop(context, int.tryParse(_ctrl.text)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, int.tryParse(_ctrl.text)),
          child: const Text('Calcular'),
        ),
      ],
    );
  }
}
