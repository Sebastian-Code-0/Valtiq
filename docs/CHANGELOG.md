# Changelog

## Auditoría continuada: errores/UX, dependencias, migración v1, dashboard testeable, velocidad de arranque (2026-09-03 a 2026-09-05) — v1.7.0+8

Sin cambio de schema (sigue en 12) — ninguno de estos commits agregó
columnas nuevas, así que no hubo bump de versión.

**Manejo de errores y UX** (`d9e7da3`): de los 3 `StreamBuilder` que
una auditoría anterior marcaba sin `snapshot.hasError`
(`deuda_detalle.dart`, `prestamo_detalle.dart`,
`presupuestos_screen.dart`), solo `presupuestos_screen.dart` seguía
sin manejarlo — corregido mostrando el error con el helper
`mostrarAlerta` ya existente (`lib/utils/notificaciones.dart`), en vez
de un SnackBar improvisado. Los 5 `catch (_) {}` silenciosos de
`notification_service.dart` ahora hacen `debugPrint` del error real
antes de continuar (diagnóstico interno, sin cambiar el comportamiento
de no interrumpir el flujo de notificaciones).

**Dependencias** (`f659df0`): `flutter pub upgrade` (18 dependencias
transitivas dentro de las restricciones ya declaradas) y
`flutter_lints` `^5.0.0`→`^6.0.0`. `google_fonts`,
`flutter_local_notifications` y `package_info_plus` quedan sin tocar
por decisión explícita: los dos primeros exigen Flutter 3.38+/Dart
3.10+ (el instalado es 3.32.1/Dart 3.8.1), y `package_info_plus`
exige un bump de AGP/Gradle/Kotlin que afecta todo el toolchain
Android — ninguno es un problema del paquete en sí.

**Migración de cadena completa v1→v12 + 2 bugs de crash reales**
(`178eab7`): `test/db/migration_v1_test.dart` reconstruye el schema
real de schemaVersion 1 (antes de `ConfigSmtps`/`PagosDeuda`/
`GastosVariables`/`PresupuestosCategorias`) para una instalación que
nunca se actualizó desde el día 1. Escribir este test destapó 2 bugs
nunca antes ejercitados:

- El bloque `from < 3` migraba la columna `contrasena` (texto plano,
  real en v2) asumiendo que la tabla ya existía con ese schema viejo
  — pero para `from < 2`, `configSmtps` se acababa de crear en el
  MISMO upgrade con el schema actual (sin `contrasena`), y SQLite
  tiraba `no such column: contrasena` (crash real).
- El bloque `from < 4` tenía el problema al revés: `addColumn` sobre
  una columna que, para `from < 2`, ya existía desde la creación
  fresca — `duplicate column name`.
- Fix: ambos bloques ahora corren solo `if (from >= 2)`, mismo patrón
  que el `if (from >= 11)` ya existente para `tipoAmortizacion`.

También se agregó `test/services/notification_service_test.dart` (5
tests) cubriendo la deduplicación de `revisarRecordatorios()` por
`frecuenciaAviso`, con un fake mínimo de
`FlutterLocalNotificationsPlatform` para no depender de un plugin real
en el entorno de test.

**`DashboardService` nuevo** (`0d282ac`): `dashboard_screen.dart` bajó
de ~1200 a ~340 líneas. Las agregaciones (joins de deudas/préstamos
con `InteresCalculator`, combine-latest manual de ingresos/gastos
fijos/gastos variables) se movieron a
`lib/services/dashboard_service.dart`, testeable sin levantar
widgets. Los 3 widgets grandes que ya vivían como clases privadas
(`_BalanceDonut`, `_ComparativoCategorias`, `_PresupuestosCard`) ahora
son públicos y viven en `lib/screens/dashboard/widgets/`. Refactor
puro, sin cambio de comportamiento.

**Velocidad de arranque** (`e9a8bea`): medido con instrumentación
temporal que `SplashScreen` tenía un `Timer` fijo de 2 segundos en
CADA apertura de la app, sin depender de ningún trabajo real (todo el
async de `main()` ya termina antes de que esa pantalla se pinte) —
bajado a 500ms. En Android, `NotificationService.init()` llamaba a
`requestNotificationsPermission()` ANTES de `runApp()`, y ese método
espera la respuesta real del diálogo nativo de permisos (Android
13+): el primer frame de la app quedaba bloqueado hasta que el
usuario decidiera. Separado en
`NotificationService.solicitarPermisoNotificaciones()`, llamado sin
esperar después de `runApp()`. Las cards de resumen del dashboard
mostraban literalmente "$0" mientras cargaban su primer valor (sin
chequear `hasData`) — ahora muestran un `CircularProgressIndicator`
chico en su lugar.

## Bloqueo PIN/biometría, ingresos variables, fix de corrupción en migraciones (2026-09-01 a 2026-09-02) — v1.7.0+8

Sin cambio de schema (sigue en 12) — ninguno de estos commits agregó
columnas nuevas, así que no hubo bump de versión.

**Bloqueo de la app con PIN/biometría:** opt-in desde Ajustes →
Seguridad, desactivado por defecto. `AppLockService`
(`lib/services/app_lock_service.dart`) guarda todo en
`shared_preferences`: PIN con hash+salt (10.000 rondas de SHA-256,
nunca en texto plano, corrido en un isolate vía `compute()`),
`usaBiometria`, `timeoutReloqueo`. Biometría vía `local_auth` (`^2.3.0`
— la 3.x pide Dart SDK `^3.9.0`, el proyecto está en `^3.8.1`) en
Android/iOS/Windows; sin soporte oficial en Linux, descartado antes de
tocar el plugin. `AppLockOverlay` se monta vía `MaterialApp.builder`
para cubrir cualquier pantalla sin importar la profundidad de
navegación, con timeout configurable (Inmediato/30s/1min/5min/15min)
al volver de segundo plano. Android requirió pasar `MainActivity` de
`FlutterActivity` a `FlutterFragmentActivity` (el `BiometricPrompt`
nativo necesita una `FragmentActivity`) más el permiso
`android.permission.USE_BIOMETRIC`. Es solo un gate de UI a propósito:
no cifra ni desbloquea la clave AES real de `CryptoService`/SMTP —
evaluado y diferido para no arriesgar dejar esa configuración
inaccesible por un bug de esta primera versión.

- Bug real encontrado al primer uso real: `LockScreen` vivía como
  HERMANO del `Navigator` de la app dentro de un `Stack` suelto, sin
  ningún `Overlay` ancestro para el `TextField` del PIN — tocarlo
  tiraba "No Overlay widget found" en cadena. `AppLockOverlay` ahora
  se renderiza dentro de un `Overlay` propio con un `OverlayEntry`
  persistente (`initialEntries` de `Overlay` solo se lee una vez, así
  que hace falta `markNeedsBuild()` a mano en cada cambio de estado).
- El aviso de un ingreso 'unico' desactivado (ver abajo) se mostró
  primero como notificación del sistema operativo y se corrigió a un
  SnackBar (`mostrarInfo`) — decisión explícita: es información de la
  sesión actual, no algo que amerite una notificación real.
- SnackBars propios ilegibles (blanco sobre blanco, no usaban el
  helper `mostrarExito`/`mostrarAlerta` ya existente) y varias cadenas
  nuevas en voseo inconsistente con el resto de la app (tuteo) —
  corregidos.

**Ingresos variables (frecuencia):** `Ingresos.frecuencia = 'unico'`
(pago puntual, ej. un trabajo secundario) se sumaba TODOS los meses
para siempre en el dashboard, sin filtrar por fecha — el mismo bug
existía por separado en el total de la pestaña Ingresos de
`finanzas_screen.dart`. Nuevo `IngresosDao.watchTotalIngresosMes`:
'unico' solo cuenta en el mes de su propia fecha; recurrentes
('mensual'/'quincenal'/'semanal') cuentan siempre. Un 'unico' cuyo mes
ya pasó se desactiva automáticamente al abrir la app
(`NotificationService.revisarIngresosUnicosVencidos`, llamado desde
`main.dart`) — nunca se borra, sigue en el historial, solo deja de
sumar; el aviso agrupado sale como SnackBar (`ShellScreen`, mismo
patrón que `CryptoService.claveFueRegenerada`).

**`frecuencia` (mensual/quincenal/semanal) pasó a afectar el total,
no solo mostrarse:** el campo era decorativo tanto en `Ingresos` como
en `GastosFijos`. El `monto` guardado representa lo que se
recibe/paga POR PERÍODO; nuevo `lib/utils/frecuencia.dart`
(`factorMensual`) da el multiplicador para el equivalente mensual:
mensual ×1, quincenal ×2, semanal ×52/12 (no ×4 — un mes tiene en
promedio más de 4 semanas exactas). Aplicado en
`IngresosDao.watchTotalIngresosMes` y el nuevo
`GastosFijosDao.watchTotalMensualizado`. Las cards de quincenal/semanal
muestran "≈ $X / mes" para verificar el cálculo.

**Bug de corrupción silenciosa en migraciones de salto múltiple
(v9/v10 → v12 directo):** los bloques `TableMigration` de `from < 10`
y `from < 11` (para `deudas`/`prestamos`) no declaraban
`tipoAmortizacion` en su `newColumns`. Drift reconstruye la tabla con
el schema ACTUAL de `tables.dart` (que ya incluye esa columna), pero
sin `newColumns` genera `SELECT ..., "tipo_amortizacion" FROM deudas`
asumiendo que la columna ya existía — como no existía todavía en ese
punto de la cadena, SQLite (fuera de modo estricto) reinterpreta el
identificador entre comillas dobles no reconocido como **string
literal**, guardando el texto `'tipo_amortizacion'` en vez del default
`'saldo_original'`. Corrupción silenciosa, sin ningún crash. Solo le
pega a un usuario que salta varias versiones de golpe (v9 o v10 directo
a v12) — un upgrade paso a paso (v11→v12) nunca lo dispara.
`test/db/migration_v12_test.dart` ahora cubre ambos saltos.

**Otros ajustes menores de correctitud:**
- `InteresCalculator`: convención documentada explícitamente (meses
  completos + fracción de 30 días, no solo "interés compuesto") y 5
  tests de borde nuevos (año bisiesto, fracciones de 1 día), que
  destaparon un bug real en `saldo_insoluto` — un abono fechado
  después del corte consultado se ignoraba del cálculo pero igual se
  contaba en `totalAbonado`.
- `formatCOP`: la escala larga (billón=10¹², trillón=10¹⁸) ya era la
  correcta para Colombia/LatAm — verificado, no era el bug de escala
  de EE.UU. que se sospechaba. Se corrigió sí un detalle de gramática:
  singular "1 billón" en vez de "1 billones".

## Amortización bancaria real, fixes de presupuestos y cifrado SMTP (2026-08-30) — v1.7.0+8

schemaVersion **11 → 12**: nueva columna `tipoAmortizacion` en `Deudas` y
`Prestamos` (`'saldo_original'` por default, `'saldo_insoluto'` nuevo).

**Nuevo modo de amortización `saldo_insoluto` (interés bancario real):**
hasta ahora el interés siempre se calculaba sobre el monto original
completo desde la fecha del préstamo, sin importar los abonos — los
abonos solo se restaban al final ("saldo_original", ahora explícito y
sigue siendo el default). Se agregó `saldo_insoluto`: cada abono se
aplica primero al interés causado desde el corte anterior y el resto a
capital, y el interés siguiente se calcula sobre el capital YA
reducido — así es como amortiza un crédito bancario real. Se puede
elegir por deuda/préstamo (dropdown "Interés sobre" en los formularios,
mismo patrón que "Modalidad de cálculo"). También se agregó
`InteresCalculator.calcularCuotaFija`/`calcularCuotaFijaDesdeTasa`
(sistema de amortización francés de cuota fija, el mismo que usan los
bancos colombianos para créditos de libre inversión/vehículo/
hipotecario), con un botón "Calcular cuota sugerida" en los
formularios de deuda y préstamo.

- `lib/services/interes_calculator.dart`: nueva clase `AbonoInteres`
  (fecha + monto), `_resumenSaldoInsoluto()`, `calcularCuotaFija()`,
  `calcularCuotaFijaDesdeTasa()`. `resumenPrestamo`/`calcularDeudaTotal`
  ahora aceptan `tipoAmortizacion`/`abonos`/`fechaFin` opcionales,
  retrocompatibles con todos los call sites existentes.
- `deuda_detalle.dart`/`prestamo_detalle.dart`,
  `deudas_screen.dart`/`prestamos_screen.dart`, `dashboard_screen.dart`:
  las consultas que antes sumaban abonos con `groupBy + sum` en SQL
  pasan a un join sin agregar (agrupación en Dart), porque
  `saldo_insoluto` necesita la fecha de cada abono, no solo la suma.
- Gotcha real de migración: `TableMigration` (usado en los pasos v10 y
  v11 para `deudas`/`prestamos`) reconstruye la tabla con el schema
  ACTUAL de `tables.dart` en tiempo de compilación, así que cualquier
  upgrade que pase por esos bloques ya recibía `tipoAmortizacion`
  gratis — un `addColumn` incondicional en el bloque v12 producía
  `duplicate column name` para upgrades desde v9/v10. El `addColumn`
  ahora solo corre si `from >= 11`.
- `backup_service.dart`: se descubrió (y corrigió) que restaurar un
  backup exportado antes de esta columna —o antes de `modalidadCalculo`,
  el mismo hueco existía desde schemaVersion 8 sin haberse disparado
  nunca— crasheaba (`type 'Null' is not a subtype of type 'String'`).
  Nuevo helper `_conDefaults()` completa esas columnas con su default
  antes de deserializar.

**Mensaje de presupuestos excedidos corregido:** el aviso decía
"Superaste tu presupuesto de X **este mes**" sin importar el mes real
del gasto — el cálculo (comparado contra el mes de la fecha elegida)
siempre fue correcto, el mensaje no. Ahora dice el mes correcto
("en marzo de 2026") cuando no es el mes actual. También se extendió
el chequeo a la edición de un gasto existente (antes solo corría al
crear uno nuevo), restando el monto viejo del total antes de sumar el
nuevo si ambos caen en el mismo mes/categoría.

**Cifrado SMTP — 3 huecos corregidos:**
- `CryptoService.claveFueRegenerada` no se activaba si la migración
  desde `valtiq_key.bin` fallaba por una excepción (solo si la clave
  YA estaba en el almacén seguro y era corrupta) — ahora se activa en
  ambos casos.
- Esa bandera nunca se leía en ningún lado de la app. `ShellScreen`
  ahora muestra un aviso al usuario si la clave se regeneró en este
  arranque, con acceso directo a reconfigurar el SMTP.
- Se agregó `CryptoService.usaAlmacenSeguroOverride`
  (`@visibleForTesting`) para poder mockear la rama de Keystore/
  Keychain en `flutter test` sin depender de un dispositivo real
  (`Platform.isAndroid` refleja el host real, nunca Android en CI) —
  `crypto_service_test.dart` ahora cubre esa rama completa, incluida
  la migración y sus dos modos de fallo.

## Clave de cifrado SMTP en Keystore/Keychain en Android/iOS (2026-08-27) — v1.6.0+7

Sin cambio de schema, sin bump de versión. La clave AES de
`CryptoService` dejaba de estar realmente protegida en el escenario
que importa: alguien con acceso al almacenamiento completo de la app
(dispositivo rooteado, backup vía ADB, malware) obtenía la base
cifrada y el archivo de la clave (`valtiq_key.bin`) uno junto al
otro. En Android/iOS ahora la clave se guarda en Android
Keystore/iOS Keychain vía `flutter_secure_storage`, respaldada por
hardware (TEE/StrongBox en Android, Secure Enclave en iOS) en vez de
un archivo plano. Linux/Windows mantienen el archivo como fallback:
ninguno de los dos tiene un keystore de escritorio confiable (el
crash `KeyringLocked` de `flutter_secure_storage` en Linux ya había
descartado antes ese camino ahí).

- `lib/services/crypto_service.dart`: `init()` ramifica por
  plataforma. Android/iOS leen/escriben la clave (base64) en
  `flutter_secure_storage`; Linux/Windows siguen con
  `valtiq_key.bin` en `getApplicationSupportDirectory()`.
- Migración automática y silenciosa para instalaciones Android
  existentes: si no hay clave en el almacén seguro, se busca
  `valtiq_key.bin` en `getApplicationDocumentsDirectory()` (donde
  vivía antes de este cambio), se copia al almacén seguro y se borra
  el archivo. Si no se encuentra o falla la lectura, se genera una
  clave nueva como antes (con la misma pérdida de datos cifrados
  previos que ya manejaba el caso de clave corrupta).
- iOS no tenía instalaciones previas (el proyecto no había agregado
  la plataforma iOS todavía), así que ahí no aplica migración: la
  clave se genera directo en Keychain la primera vez.
- `android/app/build.gradle.kts`: `minSdk` sube a 23 y `compileSdk` a
  36 (antes 21 y el default de Flutter) — requeridos por
  `flutter_secure_storage`, que respalda la clave en Keystore vía
  EncryptedSharedPreferences/Tink.
- `test/services/crypto_service_test.dart` no cambió: corre en el
  host de desarrollo (no Android/iOS), así que sigue ejercitando la
  rama de archivo plano sin tocar `flutter_secure_storage` — ese
  plugin no es mockeable en `flutter test` sin un dispositivo/
  emulador real, así que la rama de almacén seguro se verifica
  manualmente en un dispositivo Android antes de dar esto por
  cerrado.

## Fechas de negocio normalizadas a medianoche UTC (huso horario) (2026-08-24) — v1.6.0+7

schemaVersion **10 → 11**: las fechas de transacción (no los
timestamps de auditoría) pasan de instante local crudo a fecha civil
normalizada, eliminando el riesgo de que un viaje o cambio de zona
horaria del dispositivo corra una transacción a otro día o voltee un
badge "Vencido". Bump de versión (1.5.0+6 → 1.6.0+7) por el mismo
motivo que el ciclo anterior: incluye un cambio de schema real.

### Fix hacia adelante: fechas de negocio como valor civil, no instante
- Nuevo `lib/utils/fecha_civil.dart`: `normalizarFechaCivil(DateTime)`
  (envuelve año/mes/día en `DateTime.utc(...)` antes de guardar) y
  `fechaCivilGuardada(DateTime)` (`.toUtc()` antes de extraer
  año/mes/día al leer). Aplicado en los 5 formularios y los 2 diálogos
  de abono/pago que capturan una fecha de negocio.
- Comparaciones "vencido" (`deudas_screen.dart`, `prestamos_screen.dart`)
  y la ventana de recordatorios en
  `notification_service.dart::revisarRecordatorios()` ahora extraen el
  día civil con `.toUtc()` antes de comparar, en vez de usar
  `DateTime.now()` local crudo contra el valor guardado.
- `lib/services/interes_calculator.dart`: `fechaInicio`/`fechaFin` se
  extraen ahora vía `.toUtc()` (`_diaCivil()`); el default de
  `fechaFin` pasa de `DateTime.now()` a `normalizarFechaCivil(DateTime.now())`.
  Sin este ajuste, leer `.year`/`.month`/`.day` directo de una fecha ya
  normalizada corría el riesgo de dar el día equivocado según el huso
  del dispositivo — se verificó corriendo el test suite completo con
  `TZ=America/Bogota` (UTC-5) y `TZ=Asia/Tokyo` (UTC+9) para confirmar
  que el resultado no depende de la zona horaria de quien lo ejecuta.
- `lib/db/daos/gastos_variables_dao.dart`: los 3 métodos que filtran
  por mes construían el rango con `DateTime(anio, mes, 1)` (local);
  como la columna `fecha` ahora es UTC-medianoche, el rango pasa a
  `DateTime.utc(anio, mes, 1)` para no dejar fuera transacciones de
  inicio de mes.
- Corregido de paso: `recordatorio_form.dart` comparaba la fecha
  guardada contra la nueva con `!=` para decidir si resetear la
  deduplicación — `DateTime.==` en Dart también compara el flag
  `isUtc` (no solo el instante), así que esa comparación habría
  disparado siempre. Se cambió a `isAtSameMomentAs()`.

### Migración v10 → v11
- `lib/db/database.dart`: 7 `TableMigration` (Deudas, Prestamos,
  PagosDeuda, PagosRecibidos, Ingresos, GastosVariables, Recordatorios)
  con `CAST(strftime('%s', date(col, 'unixepoch', 'localtime')) AS
  INTEGER)` — interpreta el epoch guardado en el huso ACTUAL del
  dispositivo (no se puede saber en qué huso se creó cada dato viejo)
  y lo reconvierte a medianoche UTC de esa misma fecha civil.
  `creadoEn`/`actualizadoEn`/`ultimaNotificacion`/`ultimoEnvioCorreo`
  no se tocan.
- Nuevo test `test/db/migration_v11_test.dart`: reconstruye el schema
  v10 completo con fechas de hora arbitraria (23:47, etc.) y verifica
  que cada una migra al día civil correcto — usando
  `isAtSameMomentAs()`, no `==`, por el mismo motivo de arriba.
  Verificado también con `TZ=Asia/Tokyo`.

## Montos enteros, fix de backups viejos y corrección de docs de notificaciones (2026-08-24) — v1.5.0+6

schemaVersion **9 → 10**: todas las columnas de dinero pasan de REAL
(`double`) a INTEGER (`int`, peso colombiano entero sin centavos). Bump
de versión (1.4.0+5 → 1.5.0+6) porque este ciclo incluye un cambio de
schema real (no solo docs/fixes de UI como el ciclo anterior).

### Montos de dinero: double → int
- `lib/db/tables.dart`: `Deudas.montoOriginal`/`cuotaMensual`,
  `Prestamos.montoPrestado`, `PagosRecibidos`/`PagosDeuda.montoAbonado`,
  `Ingresos.monto`, `GastosFijos.monto`, `GastosVariables.monto`,
  `PresupuestosCategorias.limiteMensual` pasan de `RealColumn` a
  `IntColumn`. `tasaInteres` (porcentaje, no dinero) no se toca.
- Motivo: la app ya mostraba y capturaba los montos como enteros
  (`formatCOP`/`CopInputFormatter` nunca permitían decimales); usar
  `double` para el almacenamiento y el cálculo de interés compuesto
  permitía deriva de precisión de punto flotante acumulable entre
  abonos sucesivos — el "parche" ya existente de tolerancia de $1 en
  la validación de saldo pendiente era, en parte, un síntoma de esto.
- Migración v9→v10 (`lib/db/database.dart`): 8 `TableMigration` con
  `CAST(ROUND(columna) AS INTEGER)` para redondear (no truncar) los
  valores existentes al peso más cercano.
- `lib/services/interes_calculator.dart`: entradas/salidas de dinero
  en `int`; el cálculo intermedio sigue en `double` (fórmula continua)
  y se redondea una sola vez al final antes de devolver el resultado.
- `lib/utils/format.dart`/`currency_input.dart`: `formatCOP`/
  `formatCOPInput` amplían su firma a `num` (compatibles con `int` y
  `double`, sin cambio visual); `parseCOP` devuelve `int?` en vez de
  `double?`.
- Nuevo test `test/db/migration_v10_test.dart`: reconstruye el schema
  v9 completo sobre SQLite en memoria y verifica el redondeo correcto
  de la migración.

### Fix: restaurar un backup viejo ya no falla
- `lib/services/backup_service.dart`: un backup exportado antes de
  esta migración serializa el dinero como `double` (ej. `500000.0`);
  al restaurarlo, el `fromJson` generado por drift para una columna
  `int` rechazaba ese tipo (`TypeError`). `importarDatos()` ahora pasa
  cada fila por `_enteroEnClaves()`, que redondea las claves
  monetarias conocidas antes de deserializar.
- Nuevo test `test/services/backup_service_test.dart`: cubre el
  round-trip normal y la restauración de un backup con montos
  fraccionarios simulando el formato viejo.

### Corrección de documentación: notificaciones
- `docs/ARCHITECTURE.md`, `docs/decisions/003-android-inexact-notifications.md`
  y `docs/background-notifications-android.md` describían
  `AndroidScheduleMode.inexact` como mecanismo activo de scheduling en
  Android. El código real (`lib/services/notification_service.dart`)
  nunca lo implementó: solo revisa y dispara recordatorios de forma
  inmediata al abrir/reanudar la app, sin ningún scheduling futuro.
  Los 3 documentos se corrigieron para describir el comportamiento
  real.

### Limpieza post-migración: consistencia y tolerancias que ya sobraban
- `lib/screens/finanzas/finanzas_screen.dart`: los 3 totales (gastos
  variables, ingresos, gastos fijos) usaban `fold<double>` sobre listas
  donde `.monto` ya es `int` — funcionaba por promoción automática de
  Dart, pero quedaba inconsistente con el resto del proyecto. Ahora
  `fold<int>`; `_totalRow` amplía su parámetro a `num` (mismo patrón de
  `format.dart`).
- `lib/screens/deudas/deuda_detalle.dart` y
  `lib/screens/prestamos/prestamo_detalle.dart`: la condición
  `saldoPendienteActual <= 1` (detecta el pago del 100% para
  auto-marcar como pagada) pasa a `<= 0` — el margen de 1 peso existía
  para absorber deriva de punto flotante, que ya no es posible con
  aritmética entera exacta. La tolerancia de $1 en la *validación* del
  monto máximo del abono (regla de negocio distinta, no relacionada con
  precisión) no se tocó.
- Nuevo test `test/screens/deuda_detalle_flow_test.dart`: cubre el
  flujo real de registrar un abono exacto (marca pagada en 0) y uno
  $1 por debajo (no la marca).

## Rebrand visual, dashboard rediseñado y auto-pago (2026-08-18 a 2026-08-19) — v1.4.0+5

schemaVersion **sin cambios** este ciclo (sigue en 9) — no hay tablas,
columnas ni migraciones nuevas.

### Rebrand: paleta casi-negro/hueso y 4 acentos (antes 6)
- `AppColors` (`theme/app_colors.dart`): fondo/superficie oscuros pasan de
  azulados (`#121820`/`#1E2530`) a casi-negro neutro
  `fondoOscuro = #121212` / `superficieOscuro = #1C1C1C`; fondo/superficie
  claros pasan de blanco puro a hueso cálido
  `fondoClaro = #F5F0E6` / `superficieClaro = #FAF6ED`; texto/texto
  secundario ajustados a juego (`textoClaro #211E19`,
  `textoSecundarioClaro #756F63`, `textoOscuro #F1EFE9`,
  `textoSecundarioOscuro #9A9D97`). `acento`/`positivo` por defecto pasan de
  menta (`#2DD4A0`) a esmeralda oscuro (`#1E8A63`)
- `apariencia_screen.dart`: los 6 acentos predefinidos (Menta, Índigo,
  Ámbar, Rosa, Cielo, Coral) se reemplazan por 4: **Esmeralda oscuro**
  (`#1E8A63`, default), **Dorado** (`#B08D3E`), **Vino** (`#8B3A46`),
  **Morado** (`#6B4E8C`)
- `app_theme.dart`: `CardTheme` gana un borde sutil
  (`textoSecundario.withValues(alpha: 0.12)`) en ambos temas para separar
  las cards del fondo ahora que ya no hay contraste blanco/gris; colores de
  `DividerThemeData` ajustados a la nueva paleta
- Fix: ~13 lugares usaban `AppColors.acento`/`AppColors.positivo` fijos en
  vez de `Theme.of(context).colorScheme.primary`, así que no seguían el
  acento dinámico elegido por el usuario. 12 usos de `AppColors.acento` en
  `acerca_de_screen.dart` (tinte del logo, ícono de escudo),
  `dashboard_screen.dart` (tinte del logo, ícono "Prestado activo"),
  `deudas_screen.dart`/`prestamos_screen.dart` (ícono "Reactivar"),
  `prestamo_detalle.dart` (interés acumulado y diferencia por interés),
  `recordatorios_screen.dart` (ícono "Probar notificación") y
  `form_widgets.dart` → `FormSection` (ícono + fondo del contenedor) se
  corrigieron a `theme.colorScheme.primary`. El lugar #13 era distinto: los
  4 íconos del checklist de privacidad en `_FilaPrivacidad`
  (`acerca_de_screen.dart`) usaban `AppColors.positivo` fijo — también se
  cambió al acento dinámico, ya que aquí no aplica el significado semántico
  de "éxito" que sí justifica mantener `AppColors.positivo` fijo en el
  resto de la app

### Dashboard rediseñado: cards más altas, donut animado, barras de posición
- `GridView` de resumen: `childAspectRatio` 1.6 → 1.25 (cards más altas)
- La 5ª card ("Gastos variables (mes)") pasa de compartir grid 2×3 a
  ocupar el ancho completo en su propia fila, con alto calculado a partir
  del ancho de una celda del grid (`Builder` + `MediaQuery.sizeOf`) para
  mantener las mismas proporciones que las otras 4
- Espaciado normalizado a `AppSpacing.md` en todo el Dashboard (antes había
  un salto a `AppSpacing.lg` antes de Balance Mensual)
- `_PosicionPrestamosCard` se mueve arriba de Balance Mensual y gana una
  `BarraProgreso` bajo cada monto (prestado y deudas), mostrando la
  fracción de la posición total que representa cada uno
- Nuevo donut/pie animado en `_BalanceMensualCard`:
  `_BalanceDonut`/`_BalanceDonutPainter` (`dashboard_screen.dart`)
  reemplazan la lista simple de `_FilaMonto` por un anillo proporcional
  (gastos fijos / gastos variables / disponible), animado con
  `TweenAnimationBuilder` (600ms, `Curves.easeOutCubic`); si gastos +
  variables superan los ingresos, se reescalan entre sí para llenar el
  anillo sin la porción "disponible" (evita solapar arcos más allá de
  360°). Iteraciones dentro del mismo ciclo:
  - diámetro fijo (100) → parametrizado (`diametro`), con layout
    responsivo vía `LayoutBuilder`: apilado (donut 160 centrado arriba,
    montos abajo) en pantallas < 360px de ancho; lado a lado (donut 130)
    en pantallas más anchas
  - fix de costura visual entre segmentos: `dibujarArco` extiende el
    `sweepAngle` en 0.025 radianes de solape y fija `isAntiAlias = true`
    en todos los `Paint`, para que los colores se toquen de más en vez de
    dejar una línea/gap
  - el monto "Disponible" se mide con `TextPainter` antes de dibujar: si
    cabe legible dentro del anillo (`cabeAdentro`, ancho ≤ 78% del
    diámetro interior a tamaño 10) se muestra centrado con
    `FittedBox(scaleDown)` como antes; si no cabe, el anillo — que sigue
    dibujándose siempre con las fracciones reales, nunca vacío ni parcial
    — pasa a rellenarse como una torta sólida (`relleno: true` en
    `_BalanceDonutPainter`: radio completo, `PaintingStyle.fill`,
    `useCenter: true` en `drawArc`, mismos colores proporcionales) y el
    monto se muestra debajo en su propia línea

### Bug de formateo de montos: overflow de Int64 en formatCOP/formatCOPInput
- Causa raíz: `monto.abs().round()` sobre un `double` gigantesco se
  satura silenciosamente en `Int64.max` (`9223372036854775807`) en vez de
  lanzar error, mostrando un número mucho más chico e incorrecto en vez
  del monto real
- Fix: conversión basada en `String` (`abs.toStringAsFixed(0)`) que nunca
  pasa por `int`, en `formatCOP` (`utils/format.dart`) y `formatCOPInput`
  (`utils/currency_input.dart`)
- Notación compacta agregada en `formatCOP` para magnitudes extremas:
  `abs >= 1e12` → "X,XX billones" (÷1e12), `abs >= 1e18` → "X,XX
  trillones" (÷1e18), coma decimal (es_CO); así un monto nunca produce una
  cadena de 15+ dígitos que rompa layouts
- Endurecido contra un segundo borde: `toStringAsFixed` de Dart cae a
  notación exponencial (`"1e+21"`) en magnitudes ≥ 1e21, y el coeficiente
  ya dividido por 1e12/1e18 puede seguir alcanzando ese umbral si el monto
  original es lo bastante extremo. `numero_utils.dart` define
  `maxCoeficiente = 999999999999999.0`, usado por `format.dart`'s
  `_formatEscala` para acotar el coeficiente antes de formatear (agrega
  un `+` cuando el clamp se activa, y recorta un `,00` final si aplica)
- `formatCOPInput` necesitaba la misma protección pero debe preservar los
  dígitos exactos (es el formateador de edición en vivo, sin notación
  compacta), así que usa su propio clamp local en `currency_input.dart`:
  `_maxValorEdicion = 999999999999999868928.0` — no un literal de 21
  nueves, que como `double` se redondea exactamente a `1e21` (el propio
  umbral a evitar) y seguiría cayendo en notación exponencial; este es el
  `double` representable más grande estrictamente menor a `1e21`

### BarraCategoria: layout en dos líneas
- `BarraCategoria` (`utils/form_widgets.dart`), usado en Finanzas →
  Gastos Variables y en el Dashboard → Presupuestos, pasa de una sola
  `Row` (ícono + categoría + barra + monto) a dos líneas: fila superior
  con ícono + categoría + monto (alineado a la derecha), `_PistaBarra` en
  su propia fila de ancho completo debajo — la barra ya no se comprime
  casi a cero cuando el monto es largo. Padding vertical exterior
  `AppSpacing.xs` → `AppSpacing.sm`, con un nuevo espacio `AppSpacing.xs`
  entre ambas filas
- El monto se envuelve además en `Flexible` +
  `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight)`
  para que strings compactos largos (ej. "X,XX trillones") se encojan en
  vez de desbordar, sin truncar ni abreviar el texto

### Nuevo: marcar deuda/préstamo como pagado automáticamente al saldar
- `_registrarAbono` (`deuda_detalle.dart`) y `_registrarPago`
  (`prestamo_detalle.dart`): tras guardar un abono/pago exitosamente,
  recalculan el saldo pendiente real con el total actualizado
  (`pagosDeudaDao.getTotalAbonado` / `prestamosDao.getTotalAbonado` +
  `InteresCalculator.resumenPrestamo`); si el saldo resultante es ≤ 1
  (tolerancia de redondeo), llaman automáticamente a
  `DeudasDao.marcarComoPagada` / `PrestamosDao.marcarComoPagado`,
  muestran `mostrarExito` con el nombre del acreedor/deudor y vuelven a
  la lista (`Navigator.pop`)
- Siempre resuelto por `id` (`widget.deudaId` / `widget.prestamoId`) —
  nunca busca por `acreedorNombre`/`deudorNombre`, porque puede haber
  varios registros con el mismo nombre
- Mensaje de préstamo simplificado para calzar con el de deuda:
  `'Préstamo "${nombre}" ha sido pagado por completo y se movió a
  pagados.'`

### Splash nativo (Android)
- `flutter_native_splash: ^2.4.7` agregado como dev dependency (2.4.8
  existe pero requiere `meta: ^1.18.0`, incompatible con el `meta: 1.16.0`
  que el SDK de Flutter pinea vía `flutter_test`)
- `color`/`android_12.color` fijos en `"#121212"` — igual en modo claro y
  oscuro del SO, ya que el `SplashScreen` widget propio siempre usa
  `AppColors.fondoOscuro` sin importar el tema
- La imagen pasó por 3 iteraciones antes de quedar bien: el logo completo
  sin recortar (se veía distorsionado/mal encuadrado) → una imagen en
  blanco transparente (`assets/splash_blank.png`, ocultaba el ícono por
  completo) → versión final `assets/splash_icon.png`: canvas RGBA
  1152×1152 totalmente transparente con `logo_icono.png` redimensionado a
  672×672 (`LANCZOS`) y pegado centrado
- Tras cambiar la config hay que correr `dart run
  flutter_native_splash:create` para regenerar los recursos nativos de
  Android (`android/app/src/main/res/drawable*`, `values*/styles.xml`)

### Click derecho para eliminar abonos/pagos en escritorio
- `onSecondaryTap` agregado junto a `onLongPress` en los ítems de lista
  de abonos (`deuda_detalle.dart`) y pagos (`prestamo_detalle.dart`),
  ambos disparando `onEliminar` — antes solo se podía eliminar con
  long-press, poco natural con mouse en Linux/Windows

## Ciclo de estabilización post-Fase 7, continuación (2026-07 a 2026-08) — v1.3.0+4

### Presupuestos por categoría — límites mensuales de gasto
Funcionalidad nueva completa: tabla, pantalla de configuración,
progreso en el Dashboard y aviso al superar el límite.
- schemaVersion 8 → 9: nueva tabla `PresupuestosCategorias` (id,
  categoria, limiteMensual, creadoEn, actualizadoEn) con restricción
  `UNIQUE` en `categoria` (una sola fila de límite por categoría);
  migración `if (from < 9)` crea la tabla en bases existentes
- De paso se resuelven los dos `TODO` pendientes desde el ciclo
  anterior: `@TableIndex` en `PagosRecibidos.prestamoId` y
  `PagosDeuda.deudaId`; la migración también los crea vía
  `CREATE INDEX IF NOT EXISTS` para instalaciones que ya existían (las
  nuevas los reciben gratis por `onCreate`)
- Nuevo `PresupuestosCategoriasDao`: `watchPresupuestos`,
  `getAllPresupuestos` (para el backup), `getPresupuestoPorCategoria`,
  `upsertPresupuesto`, `eliminarPresupuesto`
- Nueva pantalla `PresupuestosScreen` (Ajustes → "Presupuestos por
  categoría"): lista las 8 categorías de `CategoriaGasto` con su
  límite actual o "Sin límite"; tocar una abre un diálogo para
  definir/editar el monto o quitar el límite existente
- Fix: el diálogo de edición creaba y destruía a mano un
  `TextEditingController` justo después de `Navigator.pop`, pero el
  `TextFormField` seguía vivo durante la animación de cierre del
  diálogo — reconstruirlo con el controller ya destruido lanzaba
  `A TextEditingController was used after being disposed`. Solucionado
  extrayendo el contenido del diálogo a su propio `StatefulWidget`
  (`_EditarPresupuestoDialog`), que crea y destruye su controller en su
  propio ciclo de vida (`initState`/`dispose`) en vez de manejarlo a
  mano desde la pantalla contenedora
- Fix: `upsertPresupuesto` usaba `insertOnConflictUpdate`, que por
  defecto resuelve conflictos contra la primary key (`id`) — como la
  pantalla nunca envía el `id` (no lo conoce de antemano si es la
  primera vez), SQLite intentaba insertar una fila nueva en vez de
  actualizar, chocando con la restricción `UNIQUE` de `categoria` y
  lanzando `UNIQUE constraint failed`. Ahora el conflicto apunta
  explícitamente a `categoria`
  (`onConflict: DoUpdate(..., target: [presupuestosCategorias.categoria])`)
- Nueva card `_PresupuestosCard` en el Dashboard (después del
  comparativo por categorías): por cada categoría con límite definido,
  reutiliza `BarraCategoria` (que ahora acepta un `colorOverride`
  opcional) para mostrar el gasto del mes vs. el límite, ordenadas de
  mayor a menor porcentaje usado; si no hay ningún límite definido, la
  card no se muestra. Si el gasto supera el límite, la barra se pinta
  en `AppColors.alerta` y aparece un ícono de advertencia + texto
  "Superado"
- Al registrar (no editar) un gasto variable que deja su categoría por
  encima del límite mensual, se muestra un aviso; el cálculo
  predictivo suma el monto nuevo al total ya gastado ese mes en la
  categoría antes de guardar
- Fix: ese aviso se disparaba también al editar un gasto ya existente
  cuya categoría estaba sobre el límite por otros gastos, sin relación
  con el campo que se estaba editando. Ahora el cálculo solo corre
  para gastos nuevos (`widget.gasto == null`)
- `BackupService` actualizado para incluir `presupuestosCategorias` en
  la exportación e importación (agregado en un fix aparte, apenas
  después de crear la tabla)

### Exportación e importación de datos (copia de seguridad en JSON)
- Nuevo `BackupService` (`services/backup_service.dart`):
  `exportarDatos()` arma un JSON con versión de formato, schemaVersion,
  fecha y versión de la app, más todas las tablas de datos del usuario
  (deudas, pagosDeuda, prestamos, pagosRecibidos, ingresos, gastosFijos,
  gastosVariables, recordatorios, presupuestosCategorias);
  `importarDatos()` borra y reinserta todo dentro de una sola
  `transaction()`, respetando el orden de FK (hijos antes que padres al
  borrar, padres antes que hijos al reinsertar) y preservando los ids
  originales del archivo
- `ConfigSmtps` se excluye a propósito del backup — nunca debe salir
  del dispositivo (evita filtrar la contraseña SMTP encriptada o el
  servidor de correo en un archivo compartido)
- Nuevos métodos `getAllX()` sin filtro (para exportar todo) agregados
  a los DAOs que solo tenían streams/queries filtradas:
  `GastosFijosDao`, `GastosVariablesDao`, `PagosDeudaDao`,
  `PrestamosDao.getAllPagosRecibidos`, `RecordatoriosDao`
- Nueva pantalla `RespaldoScreen` (Ajustes → "Copia de seguridad"),
  usando `file_selector` para elegir dónde guardar o desde dónde leer
  el archivo `.json` (multiplataforma: Linux, Windows, Android);
  diálogo de confirmación antes de importar (reemplaza TODOS los datos
  actuales, acción irreversible)
- Backups viejos o parciales no fallan si les falta alguna clave: se
  tratan como lista vacía en vez de lanzar excepción
- Validación mínima del archivo antes de tocar la base de datos: si
  `datos` no es un `Map`, lanza `FormatException` con mensaje claro en
  vez de un error críptico de parseo

### Sistema unificado de notificaciones (SnackBar)
- Nuevo `utils/notificaciones.dart`: `mostrarExito`, `mostrarAlerta`,
  `mostrarInfo`, cada una con su ícono (`check_circle_outline`,
  `error_outline`, `info_outline`) y color (`AppColors.positivo`,
  `AppColors.alerta`, el acento dinámico del usuario vía
  `Theme.of(context).colorScheme.primary`) consistentes
- `SnackBarThemeData` agregado al tema claro y oscuro:
  `SnackBarBehavior.floating`, esquinas redondeadas
  (`AppSpacing.radiusMd`), texto blanco
- Reemplazadas las 28 llamadas sueltas a
  `ScaffoldMessenger.of(context).showSnackBar(...)` repartidas en 15
  archivos (formularios de deuda/préstamo/ingreso/gasto, pantallas de
  deudas/préstamos/finanzas/recordatorios/config SMTP/respaldo) por la
  función que corresponde según el tipo de mensaje, sin cambiar el
  texto de ningún mensaje existente

### Barra de progreso de pago en Deudas y Préstamos
- Nuevo widget `BarraProgreso` en `form_widgets.dart`: envoltorio de
  `_PistaBarra` (ya usado por `BarraCategoria`/`BarraCategoriaComparada`)
  que recibe una `fraccion` ya calculada por quien llama y la satura a
  [0, 1] si no es finita
- Cada tarjeta de Deudas y Préstamos (`_DeudaCard`/`_PrestamoCard`)
  muestra ahora, debajo del saldo, una barra de progreso + porcentaje:
  "% pagado" en Deudas, "% cobrado" en Préstamos, calculado como
  `abonado / (abonado + saldoConInteres)`

### Fix: las pestañas del Shell se construyen recién al visitarlas
- `ShellScreen` mantenía las 5 pantallas dentro de un único
  `IndexedStack`, que las construye a todas de entrada aunque solo una
  sea visible — cualquier animación de entrada (el fundido de
  `AnimatedSwitcher`, el crecimiento de las barras con
  `TweenAnimationBuilder`) ya había terminado de correr antes de que el
  usuario llegara a ver esa pestaña por primera vez
- Ahora cada pantalla se reemplaza por un `SizedBox.shrink()` hasta que
  se visita por primera vez (lista `_visitada` por índice, actualizada
  en `_cambiarIndice`); a partir de ahí queda montada permanentemente,
  igual que antes (el `IndexedStack` sigue evitando reconstruir al
  volver a una pestaña ya visitada)

### Finanzas variables y Dashboard — navegación mensual y comparativos por categoría
- `CategoriaGasto` gana un color fijo por categoría (campo `color` +
  helper `colorPara`), independiente del acento personalizable y de
  `AppColors.alerta`, para que ninguna categoría se confunda
  visualmente con una alerta o con el acento activo
- Nuevos widgets reutilizables en `form_widgets.dart`: `SelectorMes`
  (navegación `< Mes Año >`, con la flecha de avanzar deshabilitada
  al llegar al mes actual) y `BarraCategoria` (barra horizontal
  proporcional coloreada por categoría)
- Finanzas → pestaña Variables: ahora navega meses históricos con
  `SelectorMes` (antes quedaba fija al mes actual) y muestra las
  barras de gasto por categoría del mes visible
- Dashboard: la card de comparación mensual (`_ComparativoCategorias`)
  pasa de mostrar solo mes actual vs. mes anterior a `StatefulWidget`
  con dos `SelectorMes` compactos independientes, permitiendo comparar
  cualquier par de meses
- Nuevo widget `BarraCategoriaComparada`: dos mini-barras apiladas por
  categoría más una insignia de variación (`_InsigniaVariacion`)
- `_PistaBarra` factorizado como widget privado compartido entre
  `BarraCategoria` y `BarraCategoriaComparada` para no duplicar el
  track de la barra
- `SelectorMes` gana `mesExcluido` opcional: deshabilita la flecha
  (anterior o siguiente) que llevaría exactamente a ese mes. Los dos
  `SelectorMes` del comparativo del Dashboard se pasan `mesExcluido`
  cruzado (`_mesA` excluye `_mesB` y viceversa) para que nunca puedan
  terminar mostrando el mismo mes; Finanzas Variables no lo usa
- `_InsigniaVariacion`: por encima de +300% de aumento, en vez de
  seguir mostrando un porcentaje (que llegaba a ser ilegible, ej.
  $1.000 → $500.000 = 49900%), muestra un multiplicador
  (`↑ ×20`); bajadas y alzas ≤300% siguen mostrando el porcentaje
  normal
- Estados vacíos con ícono: tanto el mensaje de la card comparativa
  del Dashboard ("Sin gastos en {mes}", vía nuevo método
  `_estadoVacio`) como el de Finanzas Variables ("No hay gastos
  variables este mes") anteponen un `Icon(Icons.calendar_month_outlined)`
  para que se note de un vistazo que es un estado intencional y no un
  error o pantalla en blanco
- Animaciones (solo Flutter puro, sin dependencias nuevas):
  `_PistaBarra` anima `widthFactor` de 0 al valor final con
  `TweenAnimationBuilder` (600ms, `Curves.easeOutCubic`), heredada por
  `BarraCategoria` y `BarraCategoriaComparada`; el bloque que depende
  del mes visible (total + barras + lista en Finanzas Variables;
  resumen + barras pareadas en el comparativo del Dashboard) hace un
  fundido con `AnimatedSwitcher` (400ms) al cambiar de mes
- Fix: `SelectorMes` desbordaba (overflow) en celulares cuando el
  comparativo del Dashboard mostraba dos selectores lado a lado con
  el nombre completo del mes (ej. "Julio 2026"). Ahora es responsivo:
  en pantallas angostas (`MediaQuery.sizeOf(context).width < 600`)
  abrevia a formato "Jul 26"; en pantallas anchas (tablet/desktop)
  mantiene el nombre completo
- Fix: `_InsigniaVariacion` podía mostrar "↓ 100%" en una baja que en
  realidad dejaba remanente (ej. $5.000 → $5 = -99.9%, que `.round()`
  inflaba a -100%). Ahora una baja solo se muestra como "100%" cuando
  la categoría se elimina por completo (`montoB == 0`); si queda
  remanente se topa en 99%

### Integridad de datos y ciclo de vida de recordatorios
- Borrado de deudas/préstamos con pagos asociados ahora es
  transaccional y respeta integridad referencial (FK enforcement);
  manejo de errores agregado a los formularios de recordatorio y SMTP
- Ciclo de vida de recordatorios ligados a deuda/préstamo/gasto fijo
  centralizado en los DAOs (antes vivía repetido e incompleto en las
  pantallas): marcar pagado/activo, eliminar y reactivar el registro
  original ahora sincronizan correctamente la activación del
  recordatorio vinculado, sin importar desde qué pantalla se dispare
- Nuevo botón "vaciar inactivos" en Recordatorios (borrado masivo
  manual de recordatorios desactivados)
- Eliminado `marcarComoVencido` de PrestamosDao (código muerto, sin
  caller y desincronizado del ciclo de vida de recordatorios)

### Seguridad
- CryptoService migrado de AES-256-CBC a AES-GCM autenticado; ante
  fallo de desencriptado (clave o formato antiguo) se autoregenera la
  clave y se loguea, en vez de crashear
- En Linux/Windows, la base de datos (valtiq.db) y la clave de
  encriptación (valtiq_key.bin) se mueven de la carpeta de Documentos
  del usuario a la carpeta de soporte de la app
  (getApplicationSupportDirectory); Android no cambia (sigue en su
  directorio de documentos privado, ya usado por instalaciones
  existentes)
- Android: `allowBackup="false"` en AndroidManifest.xml — sin esto,
  Auto Backup/`adb backup` podían extraer `valtiq.db` +
  `valtiq_key.bin` juntos y desencriptar la contraseña SMTP

### Validaciones UX
- Abonos y pagos a deudas/préstamos ya no pueden superar el saldo
  pendiente real (sin recortar a 0), cerrando un loophole que
  permitía sobrepagar de a $1 indefinidamente una vez saldada la
  deuda

### Rendimiento
- revisarRecordatorios() carga en batch las referencias de
  deuda/préstamo/gasto de todos los recordatorios en vez de una query
  por recordatorio, y reutiliza una sola conexión SMTP para todos los
  correos de una misma revisión
- Quitada la animación de fade al cambiar de pestaña en el Shell de
  navegación (reconstruía las 5 pantallas en cada cambio)

### Refactors — reducción de duplicación
- `FormularioGuardadoMixin` aplicado a los 6 formularios principales
  y a los diálogos de registrar abono/pago
- `theme.colorSecundario` (AppThemeExtension) reemplaza el cálculo
  repetido de isDark en 7 pantallas
- `InfoRow` compartido entre las pantallas de detalle de deuda y
  préstamo
- `CategoriaGasto` como origen único de nombre+ícono de categoría de
  gasto variable
- `AppChip` y `AtenuableCard` reemplazan chips y el patrón
  Opacity(0.6) duplicados en varias pantallas
- Tests agregados para SmtpService, DeudasDao, PrestamosDao,
  formatCOP y helpers de formato de fecha

### Preparación para publicación
- Firma de release Android configurada con keystore

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
