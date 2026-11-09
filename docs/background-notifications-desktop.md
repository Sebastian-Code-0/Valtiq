# Notificaciones en background — Linux y Windows

## Comportamiento actual

Las notificaciones se evalúan en revisarRecordatorios(), que
se ejecuta al abrir la app. Esto funciona correctamente con
la app abierta o al volver a abrirla. No hay ningún mecanismo
de disparo automático con la app cerrada en ninguna plataforma
desktop.

## Por qué no hay background en desktop

Flutter desktop no tiene mecanismo de background execution.
Cuando la app está cerrada el proceso no existe en memoria
y ningún código Dart puede ejecutarse.

A diferencia de Android, Linux y Windows no exponen una API
estándar que Flutter pueda usar para despertar la app o
ejecutar código en background sin herramientas externas.

## Qué se necesitaría en Linux

Un systemd user timer externo al proyecto:

```ini
# ~/.config/systemd/user/valtiq-check.timer
[Timer]
OnBootSec=5min
OnUnitActiveSec=1h

# ~/.config/systemd/user/valtiq-check.service
[Service]
ExecStart=/usr/bin/valtiq --check-reminders
```

Requeriría compilar Valtiq con soporte de argumentos CLI y
distribuir los archivos .timer y .service junto a la app.

## Qué se necesitaría en Windows

Una tarea en el Task Scheduler de Windows que ejecute Valtiq
periódicamente con un argumento CLI especial, más un instalador
que registre la tarea automáticamente.

## Decisión

Se deja para una fase futura. Los usuarios de desktop
típicamente abren la app cuando la necesitan, y los
recordatorios se evalúan al abrir — comportamiento suficiente
para el caso de uso actual.
