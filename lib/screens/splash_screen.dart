import 'dart:async';

import 'package:flutter/material.dart';

import '../db/database.dart';
import '../theme/theme.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Puramente decorativo: para cuando esta pantalla llega a pintarse,
    // main() ya terminó todo su trabajo async real (crypto, notificaciones,
    // estado de bloqueo) — no hay nada más que esperar acá. Antes eran 2s
    // fijos en CADA apertura de la app, sin relación con ningún trabajo
    // real; bajado a un valor que alcanza a mostrar el logo sin sentirse
    // como una espera.
    Timer(const Duration(milliseconds: 500), _navegar);
  }

  void _navegar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ShellScreen(db: widget.db),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoOscuro,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo_horizontal.png',
              width: 260,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'Tu dinero, tu control',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
