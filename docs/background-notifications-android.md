# Notificaciones en background — Android

## Comportamiento actual

Las notificaciones se evalúan en revisarRecordatorios(), que
se ejecuta al abrir la app. Esto funciona correctamente con la
app abierta o al volver a abrirla.

Adicionalmente, al evaluar un recordatorio la app programa una
notificación futura con AndroidScheduleMode.inexact via
flutter_local_notifications. Android puede disparar esa
notificación aunque la app esté cerrada, con una tolerancia
de hasta ~15 minutos respecto a la hora programada.

## Por qué no se usó WorkManager

WorkManager fue implementado y probado en Samsung A52.
Resultado: las tareas periódicas fallan silenciosamente con
battery optimization activa (comportamiento por defecto en
Samsung y la mayoría de fabricantes Android).

El único workaround es pedirle al usuario que desactive la
optimización de batería para Valtiq en los ajustes del sistema
— fricción inaceptable para una app de uso personal.

## Por qué no se usó exactAllowWhileIdle ni alarmClock

- exactAllowWhileIdle: lanza PlatformException en dispositivos
  donde SCHEDULE_EXACT_ALARM no está pre-concedido
  (mayoría de Android 12+).
- alarmClock: funciona sin permisos especiales pero crea
  entradas visibles en la app de Reloj del sistema con sonido
  de alarma — inaceptable para recordatorios financieros.

## Solución adoptada: inexact scheduling

AndroidScheduleMode.inexact no requiere permisos especiales,
no crea entradas en el Reloj del sistema, y Android respeta
la notificación programada con ~15 min de tolerancia.
Para recordatorios de pagos esta tolerancia es aceptable.

## Mejora futura posible

Detectar en runtime si SCHEDULE_EXACT_ALARM está disponible
y usar exactAllowWhileIdle en ese caso, con fallback a inexact.
