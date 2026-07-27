import 'package:flutter/material.dart';

import '../db/database.dart';
import 'dashboard/dashboard_screen.dart';
import 'deudas/deudas_screen.dart';
import 'finanzas/finanzas_screen.dart';
import 'prestamos/prestamos_screen.dart';
import 'recordatorios/recordatorios_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key, required this.db});

  final AppDatabase db;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      DashboardScreen(db: widget.db),
      DeudasScreen(db: widget.db),
      PrestamosScreen(db: widget.db),
      FinanzasScreen(db: widget.db),
      RecordatoriosScreen(db: widget.db),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pantallas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Deudas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: 'Préstamos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Recordatorios',
          ),
        ],
      ),
    );
  }
}
