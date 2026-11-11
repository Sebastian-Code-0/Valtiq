# Notificaciones en background — Android

## Comportamiento actual (desde 2026-11-10)

Los recordatorios se le dejan **programados al sistema operativo** con
`zonedSchedule` (flutter_local_notifications). Suenan a la hora que el
usuario eligió (`Recordatorios.horaAviso`/`minutoAviso`) **aunque Valtiq
esté cerrado**, y sobreviven a reiniciar o apagar el celular. Todo es local:
no hay servidor, ni FCM, ni conexión de red.

Piezas (`lib/services/`):

- `notification_planner.dart` — función pura que decide qué avisos programar
  y para cuándo (ventana de `diasAnticipacion` días antes hasta 7 días
  después, frecuencia única/diaria, repetición mensual, horizonte de 45 días,
  tope de 60 avisos). Cubierta por `test/services/notification_planner_test.dart`.
- `NotificationService.sincronizar(db)` — se llama al arrancar y cada vez que
  la app vuelve a primer plano:
  1. `conciliarProgramados`: anota como "ya avisados" los avisos programados
     cuya hora ya pasó (sonaron con la app cerrada), para no repetirlos.
  2. `revisarRecordatorios`: avisa de inmediato lo que debió sonar y no sonó
     (recordatorio creado después de su hora, permiso recién concedido),
     reprograma los mensuales vencidos y envía los correos.
  3. `replanificar`: cancela lo programado y lo programa de nuevo.
- `NotificationService.observarCambios(db)` — vuelve a planear cada vez que
  cambia la tabla `recordatorios` (crear, editar, borrar, pagar una deuda…).

## Reinicio y apagado

`AndroidManifest.xml` declara `RECEIVE_BOOT_COMPLETED` y los receptores del
plugin (`ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`).
Al encender o reiniciar, el plugin vuelve a registrar los avisos pendientes
sin que el usuario abra la app.

## Hora aproximada vs. hora exacta

- **Por defecto:** `AndroidScheduleMode.inexactAllowWhileIdle`. No necesita
  ningún permiso especial; Android puede retrasar el aviso unos minutos para
  ahorrar batería.
- **Opcional** (Configuración → Notificaciones → "Avisar a la hora exacta"):
  `exactAllowWhileIdle`, que requiere `SCHEDULE_EXACT_ALARM`. En Android 12–13
  suele venir concedido; en Android 14+ viene negado y la app abre la pantalla
  "Alarmas y recordatorios" para que el usuario decida. Si no lo concede, o lo
  retira después, se cae automáticamente al modo aproximado (nunca se pierde
  el aviso por eso).

## Recordatorio diario

Opcional (apagado por defecto): un aviso diario a la hora elegida para anotar
los gastos del día (`matchDateTimeComponents: time`).

## Límites conocidos

- **"Forzar detención":** Android cancela todas las alarmas de la app hasta
  que el usuario la abra de nuevo. Ninguna app puede evitarlo.
- **Fabricantes con ahorro de batería agresivo** (Xiaomi, Huawei, Oppo…):
  pueden bloquear el receptor de arranque o retrasar avisos. La pantalla de
  Notificaciones le explica al usuario qué ajustes revisar.
- **Correos:** una notificación programada no ejecuta código, así que los
  recordatorios por correo se siguen enviando solo al abrir la app.
- **Husos horarios:** la hora se entrega a Android como instante absoluto
  (UTC). Si el usuario cambia de huso u horario de verano, los avisos ya
  programados suenan a la hora vieja hasta que abra la app (que replanifica).
- **Pendiente de verificar en dispositivo real:** que un aviso cuya hora pasó
  con el celular apagado se muestre al encender.

## Alternativas descartadas

- **WorkManager:** implementado y probado en un Samsung A52; las tareas
  periódicas fallan en silencio con la optimización de batería activa.
- **alarmClock:** crea entradas visibles en la app Reloj, con sonido de alarma.
- **Push desde servidor (FCM):** requiere servidor propio y servicios de
  Google; incompatible con la privacidad del proyecto y con F-Droid.
