import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../db/database.dart';
import 'smtp_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get _soportado =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  static Future<void> init() async {
    if (_initialized || !_soportado) return;
    const linux = LinuxInitializationSettings(defaultActionName: 'Abrir');
    const settings = InitializationSettings(linux: linux);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_soportado) return;
    await init();
    const linuxDetails = LinuxNotificationDetails(
      defaultActionName: 'Abrir',
      urgency: LinuxNotificationUrgency.normal,
    );
    const details = NotificationDetails(linux: linuxDetails);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<int> revisarRecordatorios(AppDatabase db) async {
    await init();
    final recordatorios = await db.recordatoriosDao.getRecordatoriosActivos();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    int notificados = 0;
    for (final r in recordatorios) {
      final diaAlerta = DateTime(
        r.fechaAlerta.year,
        r.fechaAlerta.month,
        r.fechaAlerta.day,
      );
      final diasFaltantes = diaAlerta.difference(hoy).inDays;

      final dentroDeVentana =
          diasFaltantes <= r.diasAnticipacion && diasFaltantes >= -7;
      if (!dentroDeVentana) continue;

      final body = _bodyParaRecordatorio(diasFaltantes);
      final tipo = r.tipoNotificacion;

      if (tipo == 'sistema' || tipo == 'ambos') {
        await showNotification(id: r.id, title: r.titulo, body: body);
        notificados++;
      }
      if (tipo == 'correo' || tipo == 'ambos') {
        await SmtpService.enviarCorreo(
          db: db,
          asunto: 'Recordatorio: ${r.titulo}',
          cuerpo: '${r.titulo}\n\n$body',
        );
      }
    }
    return notificados;
  }

  static String _bodyParaRecordatorio(int diasFaltantes) {
    if (diasFaltantes == 0) return 'Es hoy';
    if (diasFaltantes < 0) {
      final n = -diasFaltantes;
      return 'Vencido hace $n ${n == 1 ? 'día' : 'días'}';
    }
    if (diasFaltantes == 1) return 'Mañana';
    return 'En $diasFaltantes días';
  }

  static Future<void> cancelar(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }
}
