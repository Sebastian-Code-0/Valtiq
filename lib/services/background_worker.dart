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
      WidgetsFlutterBinding.ensureInitialized();
      final db = AppDatabase(AppDatabase.openConnection());
      await CryptoService.init();
      await NotificationService.init();
      await NotificationService.revisarRecordatoriosAndroid(db);
      await db.close();
      return true;
    } catch (e) {
      return false;
    }
  });
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
