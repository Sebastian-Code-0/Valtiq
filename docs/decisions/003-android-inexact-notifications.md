# 003 - Notificaciones Android: inexact scheduling

## Estado

Aceptada — 2026-06. **No implementada en el código actual** (verificado
2026-08-22: `lib/services/notification_service.dart` no llama a
`zonedSchedule` ni usa `AndroidScheduleMode` en ningún punto). El
comportamiento real vigente es el descrito en
`docs/background-notifications-android.md`: revisión síncrona de
recordatorios al abrir/reanudar la app, sin ningún scheduling de
notificaciones futuras.

## Contexto

Valtiq necesita disparar notificaciones de recordatorios en
Android aunque la app esté cerrada. Se evaluaron tres mecanismos.

## Alternativas evaluadas

WorkManager (periodic tasks): implementado y probado en
Samsung A52. Las tareas periódicas fallan silenciosamente con
battery optimization activa. El workaround requiere que el
usuario desactive la optimización de batería — inaceptable.

exactAllowWhileIdle: requiere SCHEDULE_EXACT_ALARM. En
Android 12+ este permiso no está pre-concedido y lanza
PlatformException al intentar programar sin él.

alarmClock: funciona sin permisos pero crea entradas visibles
en la app de Reloj del sistema con sonido de alarma —
inaceptable para recordatorios financieros.

## Decisión

Se decidió usar AndroidScheduleMode.inexact de
flutter_local_notifications como mecanismo de scheduling. Esta
decisión quedó documentada pero no se implementó (ver "Estado"
arriba) — el código nunca llegó a programar notificaciones futuras.

## Razones

- No requiere permisos especiales.
- No crea entradas en el Reloj del sistema.
- Android respeta la hora programada con ~15 min de tolerancia.
- Para recordatorios de pagos, 15 minutos de margen es
  completamente aceptable.

## Consecuencias (de la decisión tal como quedó realmente implementada)

- No hay ningún scheduling: la notificación no se programa en
  ningún momento, ni siquiera al abrir la app.
- El recordatorio solo se evalúa y dispara (inmediato, vía `show()`)
  cuando el usuario abre o reanuda la app — nunca con la app cerrada.
- Si el usuario no abre la app en la fecha del recordatorio, no
  recibe ningún aviso hasta que vuelva a abrirla, sin límite de
  tiempo (la ventana de gracia y reprogramación mensual de
  `revisarRecordatorios()` cubren ese caso una vez la app se abre).

## Mejora futura posible

Detectar en runtime si SCHEDULE_EXACT_ALARM está disponible
y usar exactAllowWhileIdle con fallback a inexact.
