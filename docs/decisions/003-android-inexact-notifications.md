# 003 - Notificaciones Android: inexact scheduling

## Estado

Aceptada — 2026-06

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

Se usa AndroidScheduleMode.inexact de
flutter_local_notifications.

## Razones

- No requiere permisos especiales.
- No crea entradas en el Reloj del sistema.
- Android respeta la hora programada con ~15 min de tolerancia.
- Para recordatorios de pagos, 15 minutos de margen es
  completamente aceptable.

## Consecuencias

- Las notificaciones pueden llegar hasta ~15 minutos tarde.
- No hay garantía de entrega si el dispositivo está apagado.
- La notificación se programa al abrir la app. Si el usuario
  no abre la app antes de la fecha del recordatorio, la
  notificación no se programará.

## Mejora futura posible

Detectar en runtime si SCHEDULE_EXACT_ALARM está disponible
y usar exactAllowWhileIdle con fallback a inexact.
