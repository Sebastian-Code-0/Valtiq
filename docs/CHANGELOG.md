# Changelog

## Fase 6 — Saldos reales, personalización y limpieza (2026-06)

- Dashboard: saldo de deudas y préstamos calculado con
  capital + interés acumulado − abonos (antes mostraba
  montoOriginal sin descontar abonos)
- Lista de deudas: nueva fila "Saldo pendiente" en cada
  tarjeta, igual al patrón ya existente en lista de préstamos
- Pantalla "Acerca de" en Ajustes: versión, licencia GPL v3,
  enlace al repositorio y sección de privacidad
- Color de acento personalizable: 6 opciones predefinidas,
  persistido en SharedPreferences, propagado via acentoNotifier
- Botón Guardar, barra de navegación inferior y SegmentedButton
  responden al color de acento activo en ambos temas
- pubspec.yaml: description actualizada
- Validación de formato email en configuración SMTP
- Eliminados métodos muertos en DAOs: getAllRecordatorios,
  getRecordatoriosProximos, getTotalDeudaActiva,
  getAllGastosFijos, getTotalGastosFijosActivos
- Documentación completa: README, ARCHITECTURE, CHANGELOG,
  ADRs y docs de notificaciones

## Fase 5 — Notificaciones Android y recordatorios (2026-06)

- NotificationService ampliado para Android: canal
  valtiq_recordatorios, icono @drawable/ic_stat_notif,
  solicitud de permiso POST_NOTIFICATIONS en Android 13+
- revisarRecordatorios() con deduplicación por frecuencia
  (unica/diaria) y canal (sistema/correo) usando
  ultimaNotificacion y ultimoEnvioCorreo
- Lógica de repetir mensual: avanza fechaAlerta al mes
  siguiente tras disparar
- Notificaciones futuras programadas en Android con
  AndroidScheduleMode.inexact (~15 min tolerancia,
  sin permisos especiales)
- schemaVersion 5 → 6: agregar horaAviso, minutoAviso
  a Recordatorios
- WorkManager evaluado y descartado (falla silenciosamente
  en Samsung con battery optimization activa)
- Fix overflow en tarjeta de préstamos (Row → Wrap)
- Fix selector de hora: MediaQuery fuerza formato 12h AM/PM

## Fase 4 — Soporte Android (2026-05-30)

- NotificationService: rama Android con
  AndroidInitializationSettings y AndroidNotificationDetails
- AndroidManifest.xml: permisos INTERNET y POST_NOTIFICATIONS
- Diálogos de abono/pago: ancho fijo → double.maxFinite
  para evitar overflow en móvil
- Íconos de lanzamiento generados para todas las densidades
  mipmap (mdpi a xxxhdpi)
- docs/ANDROID.md: guía de compilación y diferencias vs desktop

## Fase 3 — Soporte Windows (2026-05-27)

- NotificationService: WindowsInitializationSettings y
  WindowsNotificationDetails; cancel() en try-catch
- crypto_service.dart: path.join() para compatibilidad Windows
- windows/runner/main.cpp: título capitalizado
- windows/runner/Runner.rc: metadatos capitalizados
- windows/runner/win32_window.cpp: tamaño mínimo 800×600
- docs/WINDOWS.md: guía de compilación y limitaciones

## Fase 2 — Recordatorios y SMTP (2026-05)

- Nueva tabla Recordatorios (schemaVersion 2 → 4)
- RecordatoriosDao con streams reactivos
- Pantalla de recordatorios: lista, formulario, detalle
- Notificaciones por sistema operativo y correo SMTP
- SMTP: template HTML, encriptación AES-256 (CryptoService,
  clave en valtiq_key.bin)
- PagosDeuda: nueva tabla para abonos a deudas propias
- Mejoras visuales en formularios: spacing, iconos,
  chips de fecha, FormSaveButton
- Fix: eliminación de deudas pagadas
- Locale es_CO: calendario en español, formato COP

## Fase 1 — Core (2026-05)

- Tablas drift: Deudas, Prestamos, PagosRecibidos,
  Ingresos, GastosFijos (schemaVersion 1)
- 5 DAOs con queries reactivas
- 7 pantallas: Dashboard, Deudas, Préstamos, Finanzas,
  Recordatorios, Ajustes (Apariencia + Config SMTP)
- InteresCalculator: interés simple y compuesto por
  meses calendario con prorrateo de días parciales
- Tema claro/oscuro con themeModeNotifier (ValueNotifier)
  persistido en SharedPreferences
- Formateo COP colombiano (CopInputFormatter, formatCOP)
- Shell de navegación con BottomNavigationBar de 5 pestañas
- SplashScreen con inicialización de BD y servicios

## Fase 0 — Setup inicial (2026-05-22)

- Setup inicial del proyecto Flutter
