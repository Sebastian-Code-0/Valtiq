# Changelog

## Ciclo de estabilización post-Fase 7 (2026-06) — v1.2.0

### Correcciones críticas (Tanda A)
- getSingle() → getSingleOrNull() en todos los DAOs de detalle
  (Deudas, Prestamos, GastosFijos, Ingresos, Recordatorios);
  getSaldoPendiente() en PrestamosDao actualizado con null-guard
- Recordatorios con referencia a deuda/préstamo/gasto eliminado
  ya no crashean: null-guard en notification_service.dart por cada
  case del switch de referenciaTabla
- parseCOP() force-unwrap eliminado en 7 formularios y diálogos;
  reemplazado por guard con SnackBar de error
- try-catch añadido en todos los métodos _guardar() de formularios
  y diálogos de abono/pago (7 archivos)
- snapshot.hasError añadido en los 18 StreamBuilder de la app

### Validaciones UX y lógica de negocio (Tanda B)
- Tasa de interés negativa rechazada en validadores de deuda_form
  y prestamo_form
- Cuota mensual no puede superar el monto original (validador en
  deuda_form)
- Fecha de alerta de recordatorio no puede ser en el pasado
  (firstDate: DateTime.now() en recordatorio_form)
- Marcar deuda/préstamo como pagado desactiva automáticamente sus
  recordatorios vinculados (nuevo método
  desactivarRecordatoriosPorReferencia en RecordatoriosDao)
- _referenciaId se limpia al cambiar tipo de referencia a 'ninguna'
  en recordatorio_form

### Seguridad (Tanda C)
- Contraseña SMTP ya no se precarga descifrada al abrir la pantalla;
  campo inicia vacío con hint text; al guardar con campo vacío
  conserva la contraseña cifrada existente
- _escapeHtml() completada con &quot; y &#x27; (antes solo escapaba
  &, < y >)

### Optimizaciones internas (Tanda D)
- 3 streams en finanzas_screen.dart convertidos de métodos a campos
  late final inicializados en initState
- _BalanceMensualCard simplificada de 3 StreamBuilder anidados a 1,
  usando StreamController.broadcast() con 3 StreamSubscription en
  _DashboardScreenState
- TODO comments añadidos en tables.dart para índices en
  PagosRecibidos.prestamoId y PagosDeuda.deudaId (schemaVersion 9)

### Tests unitarios (Tanda E — 60 tests en total)
- test/services/interes_calculator_test.dart: 13 tests de interés
  simple, compuesto, edge cases y convención bancaria días 29-31
- test/services/crypto_service_test.dart: 9 tests de roundtrip,
  IV aleatorio, manejo de errores
- test/utils/currency_input_test.dart: 17 tests de parseCOP,
  formatCOPInput y roundtrip
- test/db/gastos_variables_dao_test.dart: 10 tests de insert,
  filtro por mes, totalMes con BD vacía (fix del bug crítico),
  y delete

### Lógica bancaria y schemaVersion 8
- InteresCalculator: convención bancaria colombiana para días 29-31;
  función _aniversario() que usa el último día del mes cuando el día
  de inicio no existe en el mes destino
- Deudas propias: nueva opción de interés compuesto (campo
  modalidadCalculo añadido a la tabla Deudas con default 'simple');
  migración schemaVersion 7 → 8
- deuda_detalle.dart: cálculo de saldo usa resumenPrestamo() en lugar
  de calcularInteresSimple(), respetando modalidadCalculo de cada deuda
- Fecha de abono/pago no puede ser en el futuro (lastDate: DateTime.now()
  en diálogos de deuda_detalle y prestamo_detalle)
- Bump de versión: 1.1.0+2 → 1.2.0+3

## Fase 7 — Gastos variables e inteligencia financiera (2026-06)

- Nueva tabla GastosVariables (schemaVersion 6 → 7): id, descripcion,
  monto, categoria, fecha, notas (nullable), creadoEn
- GastosVariablesDao: watchGastosVariables, watchGastosPorMes,
  watchTotalPorCategoria, watchTotalMes, insert/update/delete
- Fix bug: watchTotalMes usaba watchSingle() que lanzaba excepción
  cuando no había filas; reemplazado por watch() con fallback a 0.0
- Nueva sección "Variables" en Finanzas con SegmentedButton de tres
  pestañas (Ingresos, Gastos Fijos, Variables); formulario de alta
  y edición con campo descripcion, monto, categoria (8 opciones) y fecha
- Dashboard ampliado: quinta card "Gastos variables (mes)"
- Balance mensual ahora descuenta también gastos variables al disponible
- Nueva card "Comparación con el mes pasado": frase resumen en lenguaje
  natural del total, desglose por categoría de diferencias > 0;
  muestra mensaje vacío si no hay datos del mes actual o del anterior
- Versión dinámica en Acerca de: FutureBuilder con PackageInfo.fromPlatform()
  muestra la version del APK en lugar de texto estático
- package_info_plus añadido a dependencias
- Bump de versión: 1.0.0+1 → 1.1.0+2

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
