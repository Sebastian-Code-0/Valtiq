# Notificaciones en background — Android

## Comportamiento actual

Las notificaciones se evalúan en revisarRecordatorios(), que se
ejecuta al abrir o reanudar la app. Esto funciona correctamente con
la app abierta o al volver a abrirla: se revisan todos los
recordatorios activos y se disparan de inmediato (`show()`) los que
correspondan según la ventana de aviso y la deduplicación por
frecuencia.

**No existe ningún scheduling de notificaciones futuras.** El
proyecto no llama a `zonedSchedule` ni usa `AndroidScheduleMode` en
ningún punto del código (`lib/services/notification_service.dart`).
Si el usuario no abre la app, ningún recordatorio se notifica por su
cuenta — el aviso solo llega la próxima vez que la app se abre o pasa
a primer plano, aunque la fecha del recordatorio ya haya llegado o
pasado.

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

## Solución adoptada: revisión al abrir la app, sin scheduling

De las tres alternativas evaluadas, ninguna quedó implementada como
scheduling activo. `AndroidScheduleMode.inexact` se documentó en su
momento como la opción menos mala (sin permisos especiales, sin
entradas en el Reloj del sistema, tolerancia ~15 min aceptable para
recordatorios de pagos), pero el código actual no la usa: la solución
realmente vigente es el chequeo síncrono en `revisarRecordatorios()`
al abrir/reanudar la app, descrito arriba. No se determinó si el
scheduling con `inexact` llegó a implementarse y luego se removió, o
si nunca se llegó a integrar — no hay commits recientes que toquen
`notification_service.dart` para esclarecerlo.

## Mejora futura posible

Si se quiere que los avisos lleguen sin que el usuario abra la app,
la opción de menor fricción documentada sigue siendo
`AndroidScheduleMode.inexact` (ver también la ADR 003), programada
vía `zonedSchedule` en el momento en que se crea o actualiza cada
recordatorio — hoy no implementada. Alternativamente, detectar en
runtime si `SCHEDULE_EXACT_ALARM` está disponible y usar
`exactAllowWhileIdle` en ese caso, con fallback a `inexact`.
