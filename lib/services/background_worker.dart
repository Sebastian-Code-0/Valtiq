import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../db/database.dart';
import 'crypto_service.dart';
import 'notification_service.dart';

const valtiqTareaRecordatorios = 'valtiq_revision_recordatorios';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('VALTIQ_WORKER: iniciando');
      WidgetsFlutterBinding.ensureInitialized();
      final db = AppDatabase(AppDatabase.openConnection());
      debugPrint('VALTIQ_WORKER: db ok');
      await CryptoService.init();
      debugPrint('VALTIQ_WORKER: crypto ok');
      await NotificationService.init();
      debugPrint('VALTIQ_WORKER: notif init ok');
      await NotificationService.revisarRecordatoriosAndroid(db);
      debugPrint('VALTIQ_WORKER: revisar ok');
      await db.close();
      return true;
    } catch (e, st) {
      debugPrint('VALTIQ_WORKER_ERROR: $e');
      debugPrint('VALTIQ_WORKER_STACK: $st');
      return false;
    }
  });
}

const valtiqTareaPrueba = 'valtiq_prueba_inmediata';

Future<void> dispararWorkerPrueba() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerOneOffTask(
    valtiqTareaPrueba,
    valtiqTareaPrueba,
    initialDelay: const Duration(seconds: 10),
    existingWorkPolicy: ExistingWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Future<void> registrarWorkerRecordatorios() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    valtiqTareaRecordatorios,
    valtiqTareaRecordatorios,
    frequency: const Duration(hours: 1),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
