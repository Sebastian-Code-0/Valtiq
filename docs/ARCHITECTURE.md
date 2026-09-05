# Arquitectura de Valtiq

## Base de datos (SQLite vía drift, schemaVersion 12)

### Tablas

**Deudas** — deudas propias del usuario
| Columna        | Tipo     | Notas                           |
|----------------|----------|---------------------------------|
| id             | INTEGER  | PK autoincrement                |
| acreedorNombre | TEXT     |                                 |
| montoOriginal  | INTEGER  | pesos enteros, sin centavos      |
| tasaInteres    | REAL     | default 0 — porcentaje, no dinero |
| tipoInteres      | TEXT     | 'ninguno' / 'mensual' / 'anual'          |
| modalidadCalculo | TEXT     | 'simple' / 'compuesto', default 'simple' |
| tipoAmortizacion | TEXT     | 'saldo_original' / 'saldo_insoluto', default 'saldo_original' |
| fechaPrestamo  | DATETIME |                                 |
| fechaLimite    | DATETIME | nullable                        |
| cuotaMensual   | INTEGER  | nullable, pesos enteros          |
| notas          | TEXT     | default ''                      |
| estado         | TEXT     | 'activa' / 'pagada'             |
| fechaPagoReal  | DATETIME | nullable                        |
| creadoEn       | DATETIME | default now                     |
| actualizadoEn  | DATETIME | default now                     |

**PagosDeuda** — abonos a deudas propias
| Columna      | Tipo     | Notas            |
|--------------|----------|------------------|
| id           | INTEGER  | PK autoincrement |
| deudaId      | INTEGER  | FK → Deudas.id   |
| montoAbonado | INTEGER  | pesos enteros    |
| fechaPago    | DATETIME |                  |
| notas        | TEXT     | default ''       |
| creadoEn     | DATETIME | default now      |

**Prestamos** — préstamos otorgados por el usuario
| Columna          | Tipo     | Notas                           |
|------------------|----------|---------------------------------|
| id               | INTEGER  | PK autoincrement                |
| deudorNombre     | TEXT     |                                 |
| deudorContacto   | TEXT     | default ''                      |
| montoPrestado    | INTEGER  | pesos enteros, sin centavos     |
| tasaInteres      | REAL     | default 0 — porcentaje, no dinero |
| tipoInteres      | TEXT     | 'ninguno' / 'mensual' / 'anual' |
| modalidadCalculo | TEXT     | 'simple' / 'compuesto'          |
| tipoAmortizacion | TEXT     | 'saldo_original' / 'saldo_insoluto', default 'saldo_original' |
| fechaPrestamo    | DATETIME |                                 |
| fechaPactadaPago | DATETIME | nullable                        |
| estado           | TEXT     | 'activo' / 'pagado'             |
| notas            | TEXT     | default ''                      |
| creadoEn         | DATETIME | default now                     |
| actualizadoEn    | DATETIME | default now                     |

**PagosRecibidos** — abonos recibidos de préstamos
| Columna      | Tipo     | Notas               |
|--------------|----------|---------------------|
| id           | INTEGER  | PK autoincrement    |
| prestamoId   | INTEGER  | FK → Prestamos.id   |
| montoAbonado | INTEGER  | pesos enteros       |
| fechaPago    | DATETIME |                     |
| notas        | TEXT     | default ''          |
| creadoEn     | DATETIME | default now         |

**Ingresos**
| Columna       | Tipo     | Notas                                          |
|---------------|----------|-------------------------------------------------|
| id            | INTEGER  | PK autoincrement                               |
| concepto      | TEXT     |                                                 |
| monto         | INTEGER  | pesos enteros — monto POR PERÍODO, no ya mensual (ver nota abajo) |
| frecuencia    | TEXT     | 'mensual' / 'quincenal' / 'semanal' / 'unico'  |
| fecha         | DATETIME |                                                 |
| notas         | TEXT     | default ''                                     |
| activo        | BOOLEAN  | default true                                   |
| creadoEn      | DATETIME | default now                                    |
| actualizadoEn | DATETIME | default now                                    |

**GastosFijos**
| Columna       | Tipo     | Notas                               |
|---------------|----------|-------------------------------------|
| id            | INTEGER  | PK autoincrement                    |
| concepto      | TEXT     |                                     |
| monto         | INTEGER  | pesos enteros — monto POR PERÍODO, no ya mensual (ver nota abajo) |
| frecuencia    | TEXT     | 'mensual' / 'quincenal' / 'semanal' |
| diaCobro      | INTEGER  | nullable                            |
| notas         | TEXT     | default ''                          |
| activo        | BOOLEAN  | default true                        |
| creadoEn      | DATETIME | default now                         |
| actualizadoEn | DATETIME | default now                         |

**Qué hace `frecuencia` (2026-09-02):** el `monto` de `Ingresos`/`GastosFijos`
siempre representa lo que se recibe/paga EN CADA período, nunca un total ya
mensualizado. `lib/utils/frecuencia.dart` (`factorMensual`) define el
multiplicador para llevarlo a un equivalente mensual: mensual ×1, quincenal
×2, semanal ×52/12 (no ×4 — un mes tiene en promedio más de 4 semanas
exactas). Se usa en `IngresosDao.watchTotalIngresosMes` y
`GastosFijosDao.watchTotalMensualizado`, consumidos por el dashboard y por
los totales de `finanzas_screen.dart`. `Ingresos.frecuencia = 'unico'` es
distinto: no se prorratea, y solo cuenta en el total del mes de su propia
`fecha` — un ingreso 'unico' cuyo mes ya pasó se desactiva automáticamente al
abrir la app (`NotificationService.revisarIngresosUnicosVencidos`, llamado
desde `main.dart` junto a `revisarRecordatorios`). El aviso es un
**SnackBar** (`mostrarInfo`, vía `NotificationService.ingresosUnicosDesactivados`
leído una sola vez en `ShellScreen.initState()` — mismo patrón que
`CryptoService.claveFueRegenerada`), no una notificación del sistema
operativo: es información de la sesión actual, no algo que amerite salir de
la app. No se borra — sigue visible en el historial, solo deja de sumar.
`GastosFijos` no tiene 'unico'
ni columna `fecha`: siempre es recurrente.

**Recordatorios**
| Columna            | Tipo     | Notas                                    |
|--------------------|----------|------------------------------------------|
| id                 | INTEGER  | PK autoincrement                         |
| titulo             | TEXT     |                                          |
| referenciaTabla    | TEXT     | nullable — 'prestamos'/'deudas'/null     |
| referenciaId       | INTEGER  | nullable — FK lógica, no enforced        |
| fechaAlerta        | DATETIME |                                          |
| diasAnticipacion   | INTEGER  | default 3                                |
| tipoNotificacion   | TEXT     | 'sistema' / 'correo' / 'ambos'           |
| repetir            | BOOLEAN  | default false — repite mensualmente      |
| activo             | BOOLEAN  | default true                             |
| creadoEn           | DATETIME | default now                              |
| frecuenciaAviso    | TEXT     | 'unica' / 'diaria'                       |
| ultimaNotificacion | DATETIME | nullable — deduplicación sistema         |
| ultimoEnvioCorreo  | DATETIME | nullable — deduplicación correo          |
| horaAviso          | INTEGER  | default 12                               |
| minutoAviso        | INTEGER  | default 0                                |

**GastosVariables**
| Columna     | Tipo     | Notas            |
|-------------|----------|------------------|
| id          | INTEGER  | PK autoincrement |
| descripcion | TEXT     |                  |
| monto       | INTEGER  | pesos enteros    |
| categoria   | TEXT     |                  |
| fecha       | DATETIME |                  |
| notas       | TEXT     | nullable         |
| creadoEn    | DATETIME | default now      |

**ConfigSmtps** — fila única (id = 1)
| Columna              | Tipo     | Notas              |
|----------------------|----------|--------------------|
| id                   | INTEGER  | PK, siempre 1      |
| servidor             | TEXT     | default ''         |
| puerto               | INTEGER  | default 587        |
| usuario              | TEXT     | default ''         |
| contrasenaEncriptada | TEXT     | nullable, AES-256  |
| tieneContrasena      | BOOLEAN  | default false      |
| correoDestino        | TEXT     | default ''         |
| nombreRemitente      | TEXT     | default 'Valtiq'   |
| ssl                  | BOOLEAN  | default false      |
| habilitado           | BOOLEAN  | default false      |
| actualizadoEn        | DATETIME | default now        |

**PresupuestosCategorias** — límite mensual de gasto por categoría
| Columna       | Tipo     | Notas                                |
|---------------|----------|---------------------------------------|
| id            | INTEGER  | PK autoincrement                     |
| categoria     | TEXT     | UNIQUE — mismo texto que CategoriaGasto.nombre |
| limiteMensual | INTEGER  | pesos enteros                         |
| creadoEn      | DATETIME | default now                          |
| actualizadoEn | DATETIME | default now                          |

### Índices
- `idx_pagos_recibidos_prestamo_id` en `PagosRecibidos.prestamoId`
- `idx_pagos_deuda_deuda_id` en `PagosDeuda.deudaId`

### Migraciones
- v1 → v2: crear ConfigSmtps, insertar fila id=1
- v2 → v3: migrar contrasena a tieneContrasena; crear PagosDeuda
- v3 → v4: agregar ConfigSmtps.contrasenaEncriptada
- v4 → v5: agregar Recordatorios.frecuenciaAviso,
           ultimaNotificacion, ultimoEnvioCorreo
- v5 → v6: agregar Recordatorios.horaAviso, minutoAviso
- v6 → v7: crear GastosVariables
- v7 → v8: añadir Deudas.modalidadCalculo (default 'simple')
- v8 → v9: crear PresupuestosCategorias; agregar los índices
           idx_pagos_recibidos_prestamo_id e idx_pagos_deuda_deuda_id
           (instalaciones nuevas ya los reciben por onCreate vía
           @TableIndex; esta migración solo cubre bases existentes)
- v9 → v10: todas las columnas de dinero pasan de REAL (double) a
            INTEGER (peso colombiano entero, sin centavos): Deudas
            (montoOriginal, cuotaMensual), Prestamos.montoPrestado,
            PagosRecibidos/PagosDeuda.montoAbonado, Ingresos.monto,
            GastosFijos.monto, GastosVariables.monto,
            PresupuestosCategorias.limiteMensual. Los valores
            existentes se redondean (`CAST(ROUND(col) AS INTEGER)`,
            no se truncan). Las tasas de interés (porcentajes) no se
            tocan, siguen en REAL. Motivo: evitar deriva de precisión
            de punto flotante en interés compuesto y sumas de abonos
            — la app ya mostraba y capturaba los montos como enteros,
            así que el tipo de almacenamiento ahora coincide con eso.
- v10 → v11: las fechas de NEGOCIO (no timestamps de auditoría) se
            normalizan a medianoche UTC de su fecha civil:
            Deudas.fechaPrestamo/fechaLimite/fechaPagoReal,
            Prestamos.fechaPrestamo/fechaPactadaPago,
            PagosDeuda/PagosRecibidos.fechaPago, Ingresos.fecha,
            GastosVariables.fecha, Recordatorios.fechaAlerta. El valor
            existente se interpreta en el huso horario ACTUAL del
            dispositivo (`'localtime'` de SQLite) y se reconvierte a
            medianoche UTC de esa misma fecha civil
            (`strftime('%s', date(col, 'unixepoch', 'localtime'))`).
            `creadoEn`/`actualizadoEn` (todas las tablas) y
            `Recordatorios.ultimaNotificacion`/`ultimoEnvioCorreo` NO
            se tocan — son instantes de auditoría reales, no fechas
            civiles. Motivo: sin esto, si el usuario viaja y cambia la
            zona horaria del dispositivo, una transacción guardada
            cerca de medianoche puede "saltar" de día al mostrarse, y
            el badge "Vencido" puede voltearse sin que el usuario haya
            hecho nada. Ver `lib/utils/fecha_civil.dart`.
- v11 → v12: agregar Deudas.tipoAmortizacion y
            Prestamos.tipoAmortizacion ('saldo_original' /
            'saldo_insoluto', default 'saldo_original' — el default
            preserva exactamente el comportamiento que ya tenían todas
            las deudas/préstamos existentes). Ver `InteresCalculator`
            más abajo para el significado de cada modo.

**Regla importante para migraciones futuras (encontrada 2026-09-02 con un
test de salto múltiple):** si una columna nueva se agrega con `addColumn`
en un bloque `from < N`, y hay bloques `TableMigration` ANTERIORES (`from <
M` con `M < N`) sobre la misma tabla, esos bloques anteriores deben declarar
la columna nueva en su propio `newColumns: [...]` — aunque esos bloques ya
estén "sellados" y no se les vaya a agregar transformación alguna para esa
columna. `TableMigration` reconstruye la tabla con el schema ACTUAL de
`tables.dart` (por eso la columna nueva SÍ aparece en la tabla resultante
del rebuild), pero sin `newColumns` drift no sabe que esa columna no
existía en la tabla vieja real en ese punto de la cadena, y genera `SELECT
..., "columna_nueva" FROM tabla_vieja` — como esa columna no existe ahí,
SQLite (fuera de modo estricto) reinterpreta el identificador entre
comillas dobles no reconocido como **string literal** en vez de lanzar
error: el valor guardado queda siendo literalmente el texto
`"columna_nueva"`, corrupción silenciosa, sin ningún crash que lo delate.
Esto solo se manifiesta para un usuario que salta VARIAS versiones de
golpe (ej. v9 o v10 directo a v12) — un upgrade paso a paso (v11→v12)
nunca lo dispara, porque para entonces la columna ya se agregó por
`addColumn`. `test/db/migration_v12_test.dart` cubre ambos saltos (v9→v12,
v10→v12) para que esto no se vuelva a colar sin test.

**Segunda regla, encontrada 2026-09-04 con el test de cadena completa
v1→v9→v12:** el mismo tipo de bug puede darse al revés — un
`TableMigration` que asume que la tabla YA EXISTÍA con un schema
histórico específico, cuando en realidad para un `from` suficientemente
viejo esa tabla se acaba de crear en el mismo upgrade con el schema
ACTUAL (vía `createTable`, que usa `tables.dart` de hoy, no el de
entonces). El caso real: el bloque `from < 3` migra la columna
`contrasena` (texto plano, existía en la v2 real) hacia
`tieneContrasena` con un `CustomExpression` que referencia `contrasena`
directamente. Para un `from < 2` (instalación en schemaVersion 1, antes
de que `ConfigSmtps` existiera), el bloque `from < 2` justo termina de
crear esa tabla con el schema actual — que ya no tiene `contrasena` en
absoluto. A diferencia del bug de `newColumns` (que corrompe en
silencio), acá el nombre de columna en el `CustomExpression` no va entre
comillas dobles, así que SQLite no lo reinterpreta como string literal:
tira `SqliteException: no such column: contrasena` y la apertura de la
base **crashea por completo** para cualquier instalación que arranque en
schemaVersion 1 y salte directo a la actual. Fix: envolver ese
`TableMigration` en `if (from >= 2)`, igual que el `if (from >= 11)` ya
existente para `tipoAmortizacion`. Regla general: si un `TableMigration`
asume una columna vieja que solo existió en un rango histórico de
versiones (no en el schema actual ni en una tabla recién creada), hay que
guardarlo con el rango `from` correcto — no basta con que el bloque
`if (from < N)` que lo contiene ya limite cuándo corre.
`test/db/migration_v1_test.dart` cubre el salto completo v1→v12.

### Fechas de negocio vs. timestamps de auditoría

Desde schemaVersion 11, los campos de fecha se dividen en dos
categorías con tratamiento distinto:

- **Fechas de negocio** (fecha de una transacción — `fechaPrestamo`,
  `fechaLimite`, `fechaPagoReal`, `fechaPactadaPago`, `fechaPago`,
  `fecha` de ingresos/gastos, `fechaAlerta`): se guardan siempre como
  medianoche UTC de su fecha civil (`normalizarFechaCivil()` en
  `lib/utils/fecha_civil.dart`), y se leen siempre con
  `fechaCivilGuardada()` (o `.toUtc()`) antes de extraer
  año/mes/día — nunca con los getters locales directos, porque drift
  reconstruye estas fechas como `DateTime` local (`isUtc == false`)
  aunque representen exactamente medianoche UTC, y leer `.year`/
  `.month`/`.day` sin pasar por `.toUtc()` puede dar el día
  equivocado según el huso horario actual del dispositivo. Comparar
  estos valores con `==`/`!=` es además engañoso incluso después de
  `.toUtc()`, porque `DateTime.==` en Dart también compara el flag
  `isUtc` (no solo el instante) — hay que usar `isAtSameMomentAs()`.
- **Timestamps de auditoría** (`creadoEn`, `actualizadoEn`,
  `Recordatorios.ultimaNotificacion`/`ultimoEnvioCorreo`): siguen
  siendo instantes reales en hora local, sin normalizar — se leen y
  comparan como siempre (getters locales directos).

### Ubicación de archivos

`valtiq.db` se guarda fuera del árbol de código: en Android usa
`getApplicationDocumentsDirectory()` (directorio privado de la app,
ya usado por instalaciones existentes); en Linux/Windows usa
`getApplicationSupportDirectory()`, porque la carpeta de Documentos
del usuario no es apropiada para archivos internos de la app.

La clave de cifrado ya no sigue la misma regla que la DB. En
Android/iOS se guarda en Android Keystore/iOS Keychain vía
`flutter_secure_storage` (respaldada por hardware — TEE/StrongBox en
Android, Secure Enclave en iOS), no en un archivo. En Linux/Windows,
sin keystore de escritorio confiable, sigue en `valtiq_key.bin` junto
a la base de datos (`getApplicationSupportDirectory()`). Instalaciones
Android previas a este cambio migran automáticamente: `CryptoService`
detecta el `valtiq_key.bin` antiguo, lo mueve al almacén seguro y
borra el archivo. En Android, `allowBackup="false"` en
AndroidManifest.xml impide además que Auto Backup/`adb backup`
extraiga `valtiq.db` fuera del dispositivo.

## Pantallas

| Pantalla      | Archivo                   | Descripción                           |
|---------------|---------------------------|---------------------------------------|
| Dashboard     | dashboard_screen.dart     | Resumen financiero con saldos reales  |
| Deudas        | deudas_screen.dart        | Lista con saldo pendiente y % pagado por deuda |
| Préstamos     | prestamos_screen.dart     | Lista con saldo pendiente y % cobrado por préstamo |
| Finanzas      | finanzas_screen.dart      | Ingresos, gastos fijos y variables    |
| Recordatorios | recordatorios_screen.dart | Lista y gestión de recordatorios      |
| Ajustes       | settings_screen.dart      | Navegación a sub-pantallas            |
| Apariencia    | apariencia_screen.dart    | Tema claro/oscuro y color de acento   |
| Config SMTP   | config_smtp_screen.dart   | Configuración de correo saliente      |
| Copia de seguridad | respaldo_screen.dart | Exportar/importar todos los datos a JSON |
| Presupuestos por categoría | presupuestos_screen.dart | Límite mensual de gasto por categoría |
| Seguridad     | seguridad_screen.dart     | Activar/desactivar bloqueo, biometría, timeout, cambiar PIN |
| Acerca de     | acerca_de_screen.dart     | Versión, licencia y repositorio       |

## Bloqueo de la app (PIN/biometría)

Opt-in desde Ajustes → Seguridad, desactivado por defecto (nadie queda
bloqueado afuera por sorpresa tras actualizar). `AppLockService`
(`services/app_lock_service.dart`) guarda todo en `shared_preferences` (no
en la base de datos ni en `flutter_secure_storage`): `bloqueoActivo`, hash+
salt del PIN, `usaBiometria`, `timeoutReloqueo`. El PIN nunca se guarda en
texto plano — hash iterado (10.000 rondas de SHA-256 con salt aleatorio de
16 bytes, corrido en un isolate aparte vía `compute()` para no trabar la UI
en la pantalla de bloqueo), suficiente para el modelo de amenaza real
(alguien con acceso físico probando PINes a mano, no un ataque remoto
masivo) sin sumar una dependencia de PBKDF2 solo para esto.

Biometría vía `local_auth` (Android/iOS/Windows — sin implementación
oficial en Linux, `AppLockService.biometriaDisponible()` descarta esa
plataforma antes de tocar el plugin, mismo patrón que
`NotificationService._soportado`). Android requiere `FlutterFragmentActivity`
en vez de `FlutterActivity` (`MainActivity.kt`) porque el `BiometricPrompt`
nativo necesita una `FragmentActivity`, y el permiso
`android.permission.USE_BIOMETRIC` en el manifest. iOS necesitará
`NSFaceIDUsageDescription` en `Info.plist` cuando se agregue la carpeta
`ios/` al repo (todavía no existe, ver `crypto_service.dart`).

**Es solo un gate de UI, deliberadamente:** no cifra ni desbloquea la clave
AES real que protege la contraseña SMTP (`CryptoService`) — se evaluó y se
decidió diferir esa integración más profunda a un pendiente separado, para
no arriesgar dejar esa configuración inaccesible por un bug de esta primera
versión del bloqueo.

`AppLockOverlay` (`screens/lock/app_lock_overlay.dart`) se monta vía
`MaterialApp.builder` (no `home`) para poder cubrir CUALQUIER pantalla con
`LockScreen` sin importar la profundidad de navegación — un
`Navigator.push` normal no alcanzaría a taparse encima de diálogos o rutas
ya abiertas. Usa `WidgetsBindingObserver` para detectar
`AppLifecycleState.paused`/`resumed` y volver a bloquear si pasó más tiempo
que `timeoutReloqueo` desde que la app quedó en segundo plano. El estado
inicial (`bloqueoInicial`) se calcula en `main()` ANTES de `runApp` — misma
convención que `themeModeNotifier`/`acentoNotifier` — para que el primer
frame ya sepa si debe arrancar bloqueada, sin parpadeo de contenido real
mientras se resuelve el `Future` async.

## Servicios

**InteresCalculator** (`services/interes_calculator.dart`)
Cálculo de interés simple y compuesto. **Convención exacta (no asumir
por el nombre "interés compuesto"):** meses completos + fracción de
mes de 30 días, aplicados dentro de la fórmula de interés
correspondiente. Un usuario podría asumir que "compuesto" significa
que solo se capitaliza al cumplirse cada mes calendario — no es así:
el mes en curso, aunque incompleto, entra a la fórmula como fracción
(días transcurridos desde el último aniversario / 30), nunca se
ignora hasta el próximo aniversario. Esto es lo que hace el resultado
reproducible: dos fechas cualquiera siempre producen el mismo
interés, sin importar qué día se abra la app o se consulte el saldo.
La unidad base es el mes contado por límites reales del calendario,
no días fijos. Los días parciales del mes en curso se prorratean
sobre 30 días. Aplica convención bancaria colombiana para préstamos
que inician los días 29, 30 o 31: si el mes destino tiene menos
días, el aniversario cae en el último día de ese mes (no se
desborda al mes siguiente). Usado en dashboard, listas y detalles
de préstamos y deudas. Los montos de entrada/salida son `int` (pesos
enteros); el cálculo intermedio (interés compuesto, prorrateo de
días) usa `double` porque la fórmula es continua, pero el resultado
monetario final se redondea una sola vez al peso más cercano antes
de devolverse — nunca se acumulan `double` sin redondear entre
llamadas sucesivas. La tasa de interés (`tasaInteres`) sigue siendo
`double` — es un porcentaje, no dinero.

`tipoAmortizacion` controla sobre qué base se calcula el interés:
`'saldo_original'` (default) lo acumula siempre sobre el monto
original completo desde `fechaPrestamo`, sin importar los abonos —
estos solo se restan al final; pensado para deuda informal sin
abonos periódicos garantizados. `'saldo_insoluto'` (real bancario)
recorre los abonos en orden cronológico y aplica cada uno primero al
interés causado desde el corte anterior y el resto a capital, así
que el interés siguiente se calcula sobre el capital YA reducido —
es la lógica de amortización de un crédito real, e implica que
`resumenPrestamo`/`calcularDeudaTotal` necesitan la lista de abonos
con fecha (`AbonoInteres`), no solo su suma.

`calcularCuotaFija`/`calcularCuotaFijaDesdeTasa` implementan el
sistema de amortización francés (cuota fija e igual en todo el
plazo): `Cuota = Capital × [i×(1+i)^n] / [(1+i)^n − 1]` — el mismo
que usan los bancos colombianos para créditos de libre inversión,
vehículo e hipotecario. Es un cálculo independiente (no cambia cómo
se acumula el interés de una deuda ya creada); sirve para sugerir una
cuota mensual fija dado un capital, tasa y número de cuotas.

**NotificationService** (`services/notification_service.dart`)
Inicializa flutter_local_notifications en Linux, Android y Windows.
Ejecuta revisarRecordatorios() al arrancar o reanudar la app: evalúa
cada recordatorio activo, aplica deduplicación por frecuencia
(unica/diaria) y canal (sistema/correo), y dispara de inmediato
(`show()`) las notificaciones que correspondan. No hay scheduling de
notificaciones futuras (no se usa `zonedSchedule`/
`AndroidScheduleMode`): si el usuario no abre la app, no llega ningún
aviso hasta que vuelva a abrirla. Las referencias de deuda/préstamo/
gasto de los recordatorios se cargan en batch (no una query por
recordatorio). También aloja `revisarIngresosUnicosVencidos()` (llamado
igual desde `main.dart`) — un nombre algo genérico para lo que hace hoy,
porque ya NO dispara una notificación del sistema, solo desactiva
ingresos 'unico' vencidos y guarda los nombres para que `ShellScreen` los
muestre con un SnackBar; ver la sección "Ingresos" más arriba para el
detalle completo.

**SmtpService** (`services/smtp_service.dart`)
Envía correos usando mailer con la configuración de ConfigSmtps.
La contraseña se desencripta en memoria antes de cada envío.
revisarRecordatorios() reutiliza una única conexión SMTP para todos
los correos de una misma revisión, en vez de abrir una por
recordatorio.

**CryptoService** (`services/crypto_service.dart`)
Encripta y desencripta la contraseña SMTP con AES-GCM autenticado
(reemplaza el AES-256-CBC original). Si el desencriptado falla por
clave o formato antiguo, se autoregenera la clave y se loguea el
fallo en vez de crashear. La clave se genera al primer uso; dónde se
persiste depende de la plataforma (Keystore/Keychain en Android/iOS,
archivo en Linux/Windows — ver "Ubicación de archivos" arriba).
`claveFueRegenerada` queda en `true` para el resto de la sesión si la
clave se regeneró por cualquier motivo (corrupta, o migración fallida
desde el archivo viejo) — `ShellScreen` lo revisa al arrancar y avisa
al usuario con un diálogo si es necesario reconfigurar el SMTP.
`usaAlmacenSeguroOverride` (`@visibleForTesting`) permite forzar la
rama de Keystore/Keychain en tests, ya que `Platform.isAndroid`
refleja el host real que corre `flutter test`.

**BackupService** (`services/backup_service.dart`)
Exporta e importa todos los datos del usuario como un único archivo
JSON. `exportarDatos()` arma un mapa con metadatos (versión de
formato, schemaVersion, fecha, versión de la app) y una clave `datos`
con todas las tablas de contenido del usuario (deudas, pagosDeuda,
prestamos, pagosRecibidos, ingresos, gastosFijos, gastosVariables,
recordatorios, presupuestosCategorias) serializadas vía `toJson()`.
`ConfigSmtps` se excluye a propósito — nunca debe salir del
dispositivo. `importarDatos()` valida el formato mínimo, y dentro de
una sola `transaction()` borra todo (hijas antes que padres, por FK) y
reinserta en batch (padres antes que hijas), preservando los ids
originales del archivo para que las referencias entre tablas sigan
siendo válidas. Usado por `RespaldoScreen` (Ajustes → "Copia de
seguridad"), que delega la elección de archivo a `file_selector`.
`_conDefaults()` completa columnas agregadas después de que el
backup fue creado (`modalidadCalculo`, `tipoAmortizacion`) con su
valor default antes de deserializar — sin esto, restaurar un backup
viejo lanza un TypeError en vez de fallar con un mensaje claro.

Compatibilidad con backups viejos (pre-schemaVersion 10): un backup
exportado antes de la migración de montos a entero serializa el
dinero como `double` (ej. `500000.0`); `jsonDecode` lo decodifica como
`double`, y el `fromJson` generado por drift para una columna `int` no
acepta ese tipo. `importarDatos()` pasa cada fila por
`_enteroEnClaves()`, que redondea (`.round()`) las claves monetarias
conocidas de cada tabla antes de deserializar, así un backup viejo se
sigue pudiendo restaurar sin fallar.

## Dashboard: DashboardService y widgets propios (2026-09-04)

`dashboard_screen.dart` bajó de ~1200 a ~340 líneas: las agregaciones
(joins de deudas/préstamos con `InteresCalculator`, y el combine-latest
manual de ingresos/gastos/gastos variables) se movieron a
`lib/services/dashboard_service.dart` — testeable sin levantar widgets,
ver `test/services/dashboard_service_test.dart`. Los tres widgets grandes
que antes vivían como clases privadas dentro de `dashboard_screen.dart`
ahora son públicos en `lib/screens/dashboard/widgets/`:
`BalanceDonut`/`BalanceDonutPainter` (`balance_donut.dart`),
`ComparativoCategorias` (`comparativo_categorias.dart`) y
`PresupuestosCard` (`presupuestos_card.dart`). Refactor puro — mismo
comportamiento, mismas queries, sin cambio de UI.

## Donut de balance mensual

`BalanceDonut` / `BalanceDonutPainter` (`lib/screens/dashboard/widgets/balance_donut.dart`,
usado dentro de `_BalanceMensualCard` en `dashboard_screen.dart`): anillo
proporcional (gastos fijos / gastos variables / disponible) pintado a
mano con `CustomPainter`, animado con `TweenAnimationBuilder` (600ms).
Los arcos se dibujan con un solape fijo de 0.025 radianes y
`isAntiAlias = true` para que los colores se toquen de más en vez de
dejar una costura visible entre segmentos. `BalanceDonut` recibe un
`diametro` parametrizable (`_BalanceMensualCard` lo elige según un
`LayoutBuilder`: apilado con donut más grande en pantallas angostas,
lado a lado con donut más chico en pantallas anchas) y mide el monto
"Disponible" formateado con `TextPainter` antes de decidir dónde
mostrarlo: si cabe legible dentro del anillo a tamaño mínimo, va centrado
con `FittedBox(scaleDown)`; si no, el `BalanceDonutPainter` recibe
`relleno: true` y pinta una torta sólida (mismas fracciones y colores,
`PaintingStyle.fill`) en vez de un anillo — nunca se muestra vacío o
parcial — y el monto se ubica debajo en su propia línea.

## Ciclo de vida de recordatorios ligados

Cuando un Recordatorio tiene `referenciaTabla`/`referenciaId`, su
activación se mantiene sincronizada con el estado del registro al
que referencia. La lógica está centralizada en los DAOs (no en las
pantallas), dentro de la misma `transaction()`:
- `DeudasDao.marcarComoPagada` / `marcarComoActiva`
- `PrestamosDao.marcarComoPagado` / `reactivarPrestamo`
- `GastosFijosDao.setActivo`
- `deleteDeudaConPagos` / `deletePrestamoConPagos` /
  `deleteGastoFijoConRecordatorios` desactivan (no borran) el
  recordatorio vinculado al eliminar el registro original

`DeudasDao.marcarComoPagada` / `PrestamosDao.marcarComoPagado` tienen dos
caminos de entrada: el botón manual "Marcar como pagada/o" (menú de la
pantalla de detalle) y, desde este ciclo, automático — `_registrarAbono`
(`deuda_detalle.dart`) / `_registrarPago` (`prestamo_detalle.dart`)
recalculan el saldo pendiente tras guardar un abono/pago y llaman al
mismo método del DAO si el saldo queda en ≤ 0 (aritmética entera
exacta desde la migración a montos enteros, ver schemaVersion 10 —
ya no hace falta margen de redondeo), siempre por `id`, nunca por
nombre. Ambos caminos terminan en el mismo
método del DAO, así que la sincronización del recordatorio vinculado
descrita arriba aplica igual sin importar cuál disparó el cambio.

`RecordatoriosDao` expone `reactivarRecordatoriosPorReferencia`
(reactiva y resetea `ultimaNotificacion`/`ultimoEnvioCorreo` para que
vuelva a notificar limpio) y `eliminarRecordatoriosInactivos`
(borrado masivo, usado por el botón "vaciar inactivos" en la vista
de inactivos). El borrado de deudas/préstamos con pagos asociados es
transaccional y respeta integridad referencial (FK enforcement).

## Utilidades compartidas

- `utils/fecha_civil.dart` — `normalizarFechaCivil(DateTime)`: envuelve
  año/mes/día en `DateTime.utc(...)` antes de guardar una fecha de
  negocio. `fechaCivilGuardada(DateTime)`: hace `.toUtc()` antes de
  extraer año/mes/día al leer una ya guardada. Ver "Fechas de negocio
  vs. timestamps de auditoría" arriba para el porqué.
- `utils/format.dart` — `formatCOP(num)`: formatea un monto en pesos
  colombianos (`$1.234.567`) vía conversión basada en `String`
  (`toStringAsFixed(0)` + agrupación de miles). Acepta `num` (no solo
  `int`) para seguir funcionando con cualquier `double` residual, aunque
  desde la migración a montos enteros (ver schemaVersion 10 arriba) casi
  todos los call sites ya pasan `int`. Para `abs >= 1e12`/`1e18` usa
  notación compacta en escala larga (es_CO): "X,XX billones"/"X,XX
  trillones", acotando el coeficiente a `numero_utils.maxCoeficiente`
  (`999999999999999.0`, con sufijo `+` cuando el clamp se activa) para
  que ni siquiera esas divisiones puedan caer en la notación exponencial
  de Dart (`"1e+21"`, umbral en magnitudes ≥ 1e21).
- `utils/currency_input.dart` — `formatCOPInput(num)`: formateador
  para el campo en edición (agrupa miles pero sin notación compacta,
  debe mostrar los dígitos exactos); tiene su propio clamp local
  (`_maxValorEdicion = 999999999999999868928.0`, el `double`
  representable más grande estrictamente menor a `1e21`) para la misma
  protección contra notación exponencial en valores extremos.
  `parseCOP(String)` devuelve `int?` (antes `double?`): redondea
  (`.round()`) si el texto trae parte decimal, aunque en la práctica
  `CopInputFormatter` ya filtra la entrada a solo dígitos mientras el
  usuario escribe, así que ese caso no ocurre desde la UI real.
  `CopInputFormatter`: `TextInputFormatter` que reformatea el texto del
  campo (agrupación de miles) en cada tecla mientras se edita un monto.
- `utils/formulario_guardado_mixin.dart` — `FormularioGuardadoMixin`:
  valida, marca estado de guardando, persiste y maneja error/snackbar
  de forma uniforme; usado por los 6 formularios principales y los
  diálogos de registrar abono/pago.
- `theme/theme_extensions.dart` — `AppThemeExtension.colorSecundario`,
  reemplaza el cálculo repetido de `isDark` en 7 pantallas.
- `utils/form_widgets.dart` — `InfoRow`, fila label→valor compartida
  entre las pantallas de detalle de deuda y préstamo. También
  `SelectorMes` (navegación `< Mes Año >` reutilizada en Finanzas
  Variables y en el comparativo del Dashboard, con variante
  `compacto` y `mesExcluido` opcional para deshabilitar la flecha que
  llevaría a un mes concreto; el texto es responsivo — nombre completo
  del mes en pantallas ≥600px de ancho, abreviado "Jul 26" en
  celulares, para no desbordar cuando hay dos selectores lado a lado),
  `BarraCategoria` (barra proporcional por categoría, con
  `colorOverride` opcional para pintarla de otro color — usado por el
  progreso de presupuestos cuando se supera el límite; layout en dos
  líneas: fila superior con ícono + nombre de categoría + monto
  —envuelto en `Flexible` + `FittedBox(scaleDown)` para que strings
  compactos largos como "X,XX trillones" se encojan en vez de
  desbordar—, `_PistaBarra` en su propia fila de ancho completo debajo
  para que nunca se comprima por un monto largo) y
  `BarraCategoriaComparada` (dos mini-barras apiladas + insignia de
  variación entre dos meses), ambas apoyadas en el widget privado
  compartido `_PistaBarra`, que anima el crecimiento del ancho con
  `TweenAnimationBuilder` (600ms, `Curves.easeOutCubic`) cada vez que
  cambia `fraccion`. `BarraProgreso` es un envoltorio más simple de
  `_PistaBarra` para cuando la fracción ya viene calculada por quien
  llama (usado en el % pagado/cobrado de Deudas y Préstamos).
- `utils/notificaciones.dart` — `mostrarExito`, `mostrarAlerta`,
  `mostrarInfo`: wrapper único sobre
  `ScaffoldMessenger.of(context).showSnackBar` con ícono y color
  consistentes según el tipo de mensaje (éxito, alerta, informativo
  con el acento dinámico del usuario). Reemplaza las 28 llamadas
  sueltas a `showSnackBar` que existían repartidas en 15 archivos.
- `utils/categoria_gasto.dart` — `CategoriaGasto`, origen único de
  nombre+ícono+color por categoría de gasto variable, con fallback a
  "otros" para valores libres no listados. El color es fijo por
  categoría (independiente del acento personalizable y de
  `AppColors.alerta`) y se usa en las barras de Finanzas Variables y
  del comparativo del Dashboard.
- `theme/app_chip.dart` — `AppChip` y `AtenuableCard`, reemplazan
  chips y el patrón `Opacity(0.6)` duplicados en varias pantallas.

## Flujo de datos

main() abre `AppDatabase` → carga SharedPreferences (tema, acento) →
`CryptoService.init()` → `NotificationService.init()` +
`revisarRecordatorios()` + `revisarIngresosUnicosVencidos()` (estas dos
sin `await`, fire-and-forget) → carga `bloqueoInicial`
(`AppLockService.bloqueoActivo()`) → `runApp` con `MaterialApp.builder`
envolviendo todo en `AppLockOverlay` → `home: SplashScreen` → tras 2s,
`ShellScreen` con `BottomNavigationBar` (que ahí sí avisa con SnackBar/
diálogo si `claveFueRegenerada` o `ingresosUnicosDesactivados` tienen
algo pendiente) → pantallas acceden a `AppDatabase` vía constructor.

Los streams de drift (watchAll, watchActivos) mantienen las
listas reactivas: cualquier insert/update/delete reconstruye
automáticamente los widgets suscritos.

El Shell de navegación no anima el cambio de pestaña con fade
(se quitó: reconstruía las 5 pantallas en cada cambio). Cada pestaña
del `IndexedStack` se reemplaza por un `SizedBox.shrink()` hasta que
se visita por primera vez, para que las animaciones de entrada de esa
pantalla (fundidos, barras que crecen) corran recién cuando el usuario
la ve, no en segundo plano desde el arranque de la app.

### Navegación mensual y comparativos de gastos variables

En Finanzas → pestaña Variables, `SelectorMes` permite navegar meses
históricos (la flecha de avanzar se deshabilita al llegar al mes
actual); el mes visible controla tanto la lista de gastos como el
stream `watchTotalPorCategoria`, cuyo resultado se dibuja como una
`BarraCategoria` por categoría (ordenadas de mayor a menor monto). El
bloque de total + barras + lista está envuelto en un
`AnimatedSwitcher` (400ms) con `key: ValueKey(_mesVariables)`, para
que el cambio de mes se vea como un fundido y no un salto brusco; el
`SelectorMes` de arriba queda fuera del `AnimatedSwitcher`. Si no hay
gastos ese mes, el estado vacío antepone un ícono de calendario al
texto.

La card `_ComparativoCategorias` del Dashboard es un `StatefulWidget`
con dos `SelectorMes` compactos independientes (mes A y mes B,
inicializados en mes anterior vs. mes actual), lo que permite comparar
cualquier par de meses. Cada `SelectorMes` recibe `mesExcluido` con el
mes que muestra el otro selector, así ninguna flecha puede llevar a
una colisión (mismo mes en A y B) — la restricción vive en la UI, sin
mensaje de error adicional. Usa dos streams de `watchTotalPorCategoria`
(uno por mes) para generar una frase resumen del total (más/menos
gastado en el mes B que en el mes A) y una `BarraCategoriaComparada`
por cada categoría con datos en A y/o B, con insignia de variación
(`_InsigniaVariacion`: porcentual hasta +300%, multiplicador tipo
`↑ ×20` por encima; una baja nunca se muestra como "100%" por
redondeo si queda remanente — solo cuando `montoB == 0` de verdad).
Si no hay datos del mes B o del mes A, el método
`_estadoVacio` muestra un ícono de calendario + "Sin gastos en
{mes}" + texto secundario invitando a registrar o avisando que no hay
histórico para comparar. Todo el bloque de resumen/estado
vacío/barras está envuelto en un `AnimatedSwitcher` (400ms) con
`key: ValueKey('$_mesA-$_mesB')`; los dos `SelectorMes` y el título
quedan fuera.
