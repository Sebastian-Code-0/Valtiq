import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/database.dart';
import '../main.dart';
import '../utils/format.dart';
import '../utils/preferencia_menu.dart';
import 'notification_service.dart';
import 'perfil_service.dart';

/// "Borrar todo": deja Valtiq como recién instalada en este dispositivo.
abstract class BorradoService {
  /// Borra, en este orden:
  /// 1. Todos los datos (deudas, préstamos, pagos, ingresos, gastos,
  ///    recordatorios, presupuestos y la configuración de correo).
  /// 2. La foto de perfil guardada.
  /// 3. Todas las preferencias: perfil, tema, PIN y bloqueo, avisos, plan
  ///    de pago, "ocultar montos", posición del menú.
  /// 4. Los avisos que estaban programados en el sistema.
  ///
  /// No se puede deshacer. La clave de cifrado del correo se conserva (sin
  /// datos que descifrar no protege nada, y regenerarla dispararía el aviso
  /// de "configuración de correo perdida" en el próximo arranque).
  static Future<void> borrarTodo(AppDatabase db) async {
    await db.transaction(() async {
      // Hijas antes que padres, igual que al importar un respaldo.
      await db.delete(db.pagosDeuda).go();
      await db.delete(db.pagosRecibidos).go();
      await db.delete(db.recordatorios).go();
      await db.delete(db.deudas).go();
      await db.delete(db.prestamos).go();
      await db.delete(db.ingresos).go();
      await db.delete(db.gastosFijos).go();
      await db.delete(db.gastosVariables).go();
      await db.delete(db.presupuestosCategorias).go();
      await db.delete(db.configSmtps).go();
    });

    await PerfilService.quitarFoto();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Lo que la app tiene en memoria vuelve a sus valores de fábrica, para
    // que la pantalla cambie al instante sin reiniciar.
    PerfilService.perfil.value = const Perfil();
    themeModeNotifier.value = ThemeMode.system;
    montosOcultosNotifier.value = false;
    menuSuperiorNotifier.value = false;
    appDesbloqueadaNotifier.value = true;

    try {
      // Sin recordatorios ni preferencias: cancela todo lo programado.
      await NotificationService.replanificar(db);
    } catch (e) {
      debugPrint('BorradoService: no se pudieron cancelar los avisos: $e');
    }
  }
}
