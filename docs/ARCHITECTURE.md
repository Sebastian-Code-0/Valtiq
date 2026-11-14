# Arquitectura de Valtiq

## Base de datos (SQLite vía drift, schemaVersion 15)

### Tablas

**Deudas** — deudas propias del usuario
| Columna        | Tipo     | Notas                           |
|----------------|----------|---------------------------------|
| id             | INTEGER  | PK autoincrement                |
| acreedorNombre | TEXT     | nombre principal ("Tarjeta Nu") |
| descripcion    | TEXT     | default '' — segunda línea ("BBVA tarjeta de crédito"), desde schemaVersion 14 |
| tipo           | TEXT     | 'persona' / 'tarjeta' / 'banco' / 'tienda' / 'otro', default 'otro' — decide la imagen (`utils/tipo_deuda.dart`), desde schemaVersion 14 |
| diaPago        | INTEGER  | nullable, 1–31 — día del mes en que toca pagar, desde schemaVersion 14 |
| montoOriginal  | INTEGER  | pesos enteros, sin centavos      |
| tasaInteres    | REAL     | default 0 — porcentaje, no dinero |
| tipoInteres      | TEXT     | 'ninguno' / 'mensual' / 'anual'          |
| modalidadCalculo | TEXT     | 'simple' / 'compuesto', default 'simple' |
| tipoAmortizacion | TEXT     | 'saldo_original' / 'saldo_insoluto', default 'saldo_original' |
| fechaPrestamo  | DATETIME |                                 |
| fechaLimite    | DATETIME | nullable                        |
| cuotaMensual   | INTEGER  | nullable, pesos enteros — en pantalla es el "pago mínimo al mes" |
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
| fechaPagoReal    | DATETIME | nullable, desde schemaVersion 13 |
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
| categoria     | TEXT     | UNIQUE — nombre de una fila de `Categorias` |
| limiteMensual | INTEGER  | pesos enteros                         |
| creadoEn      | DATETIME | default now                          |
| actualizadoEn | DATETIME | default now                          |

**Categorias** — categorías de los gastos del día a día, editables
(schemaVersion 15; antes eran fijas en `CategoriaGasto`)
| Columna  | Tipo     | Notas |
|----------|----------|-------|
| id       | INTEGER  | PK autoincrement |
| nombre   | TEXT     | UNIQUE |
| icono    | TEXT     | clave del catálogo fijo de `utils/iconos_categoria.dart` (Flutter descarta en el APK los íconos que no aparecen escritos en el código, por eso no se guarda el código del ícono) |
| color    | INTEGER  | ARGB, de la paleta `coloresCategoria` |
| orden    | INTEGER  | orden en las listas |
| creadoEn | DATETIME | default now |

`GastosVariables.categoria` y `PresupuestosCategorias.categoria` siguen
guardando el **nombre** (texto), no el id: los respaldos viejos se leen
sin conversión y renombrar es un solo `UPDATE` sobre gastos y presupuesto
dentro de la misma transacción (`CategoriasDao.actualizar`). "Otros" no se
puede renombrar ni borrar: es a donde van los gastos de una categoría
borrada. `AppDatabase.sembrarCategorias()` crea las de fábrica que falten
más una por cada nombre que usen gastos/presupuestos y no exista (para que
ningún gasto quede huérfano); se usa al crear la base, al migrar, al
restaurar un respaldo y en "Borrar todo".

Borrar una categoría (`CategoriasDao.borrar`): en una transacción borra sus
gastos del día a día de todos los meses **o** los pasa a "Otros"
(`moverAOtros`), borra su presupuesto y la categoría. La pantalla
(`BorrarCategoriaDialog`) primero dice cuántos gastos, cuánto suman y qué
límite tiene, advierte que no hay papelera y ofrece pasarlos a "Otros";
después, en la misma ventana, dice lo que se borró. Decisión del usuario
(2026-11-12). Los recordatorios no se pueden vincular a gastos del día a
día, así que no hay avisos que limpiar.

`CategoriasService.lista` (`ValueNotifier`) las tiene en memoria para pintar
ícono y color de cada gasto sin esperar a la base; se carga en `main()` y
se mantiene sola con `watchCategorias()`. Sin cargar (pruebas) responde con
las de fábrica.

**Recordatorios.diaOriginal** (schemaVersion 15, nullable): día del mes que
eligió el usuario para un recordatorio que se repite. La reprogramación
mensual (`NotificationService.revisarRecordatorios`) usa
`sumarMesesConDia(fecha, meses, diaOriginal ?? fecha.day)`: un 31 que pasó
por febrero (28) vuelve a 31 en marzo. Antes se quedaba en 28 para siempre.

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
- v12 → v13: agregar Prestamos.fechaPagoReal (nullable — Deudas ya la
            tenía desde antes, Prestamos no). Motivo: ninguna pantalla
            de detalle/lista pasaba `fechaFin` a `InteresCalculator`,
            que por defecto calcula siempre hasta HOY — una deuda o
            préstamo ya marcado como pagado seguía mostrando interés
            creciendo para siempre. `PrestamosDao.marcarComoPagado`
            ahora recibe la fecha real de pago (igual que
            `DeudasDao.marcarComoPagada`) y `deuda_detalle.dart`/
            `prestamo_detalle.dart`/`deudas_screen.dart`/
            `prestamos_screen.dart` pasan `fechaFin:
            fechaCivilGuardada(x.fechaPagoReal!)` cuando el estado es
            pagado/pagada. Préstamos ya marcados pagados bajo el schema
            viejo quedan con `fechaPagoReal = null` (no hay forma de
            reconstruir esa fecha retroactivamente) hasta que el
            usuario los reactive y los vuelva a marcar como pagados.
- v13 → v14: agregar Deudas.descripcion (default ''), Deudas.tipo
            (default 'otro') y Deudas.diaPago (nullable) para el
            rediseño de la pantalla de Deudas. Las deudas existentes
            se ven igual que antes hasta que el usuario las edite. Las
            tres columnas están declaradas en el `newColumns` de los
            `TableMigration` de `deudas` (`from < 10` y `from < 11`) y
            el `addColumn` solo corre si `from >= 11` — ver la regla de
            abajo. Test: `test/db/migration_v14_test.dart`. Un respaldo
            anterior se sigue importando (`BackupService` rellena
            `descripcion` y `tipo` con sus valores por defecto).

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

- v14 → v15: crear `Categorias` (sembrada con las de fábrica y las que ya
  usaban los gastos/presupuestos) y `Recordatorios.diaOriginal`. Mismo
  gotcha de `newColumns`: el rebuild de `recordatorios` en `from < 11`
  declara `diaOriginal` y el `addColumn` solo corre si `from >= 11`.
  `test/db/migration_v15_test.dart` cubre v13→v15 y v14→v15.
- `beforeOpen` fija también `PRAGMA busy_timeout = 3000`: la ventana de
  "Anotar gasto" del widget abre su propia conexión mientras la app puede
  tener otra abierta.

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
extraiga `valtiq.db` fuera del dispositivo. En Android 12+ eso no basta
(la transferencia directa entre celulares puede seguir activa según el
fabricante), por eso `android:dataExtractionRules` apunta a
`res/xml/data_extraction_rules.xml`, que excluye todo del respaldo en la
nube y de la transferencia entre dispositivos.

## Pantallas

| Pantalla      | Archivo                   | Descripción                           |
|---------------|---------------------------|---------------------------------------|
| Inicio        | dashboard_screen.dart     | Fecha + saludo, cuatro totales y tarjetas de balance, posición, presupuestos y comparativo |
| Deudas        | deudas_screen.dart        | Pestañas Activas (totales + cuadrícula de tarjetas), Plan de pago y Pagadas — ver "Pantalla de Deudas" |
| Préstamos     | prestamos_screen.dart     | Pestañas Por cobrar (totales + cuadrícula con "Registrar abono") y Cobrados — ver "Pantalla de Préstamos" |
| Finanzas      | finanzas_screen.dart      | Pestañas Ingresos, Gastos fijos y Día a día — ver "Pantalla de Finanzas" |
| Recordatorios | recordatorios_screen.dart | Pestañas Activos / Inactivos; una tarjeta por recordatorio con su fecha, estado y hora — ver "Pantalla de Recordatorios" |
| Ajustes       | settings_screen.dart      | Una sola pantalla con selector de secciones; cada sección es una de las pantallas de abajo |
| Perfil        | perfil_screen.dart        | Foto, nombre y apellido (el nombre saluda en Inicio) |
| Notificaciones | notificaciones_screen.dart | Permiso, hora exacta, recordatorio diario |
| Apariencia    | apariencia_screen.dart    | Tema claro/oscuro/sistema con vista previa |
| Config SMTP   | config_smtp_screen.dart   | Configuración de correo saliente      |
| Copia de seguridad | respaldo_screen.dart | Exportar/importar todos los datos a JSON |
| Presupuestos por categoría | presupuestos_screen.dart | Límite mensual de gasto por categoría |
| Seguridad     | seguridad_screen.dart     | Activar/desactivar bloqueo, biometría, timeout, cambiar PIN |
| Cómo funciona Valtiq | como_funciona_screen.dart | Guía de conceptos (interés, prorrateo, saldo insoluto, etc.) en lenguaje simple |
| Acerca de     | acerca_de_screen.dart     | Versión, licencia y repositorio       |

### Diseño de PC y de celular (2026-11-11)

`ShellScreen` decide el armazón según el ancho de la ventana
(`anchoMinimoBarraLateral` = 900 px, en `screens/barra_lateral.dart`):

- **PC (≥ 900 px):** `BarraLateral` a la izquierda (logo, las cinco
  secciones, Ajustes y el perfil al fondo) y el contenido a la derecha.
  Ajustes es una pantalla más del `IndexedStack` (`SettingsScreen` con
  `embebido: true`), no una ruta nueva. `DashboardScreen` usa el mismo límite
  para cambiar a su diseño de PC (fecha, saludo, cuatro tarjetas en fila, dos
  columnas).
- **Celular (< 900 px):** barra inferior flotante (`BarraInferior`, en
  `barra_inferior.dart`): una píldora separada de los lados y del fondo de
  la pantalla, con la sección elegida sobre un fondo tenue del color de
  marca y la insignia de recordatorios pendientes. La última sección se
  rotula "Avisos" (es Recordatorios; el nombre completo no cabe). No usa
  `extendBody`: va como `bottomNavigationBar` sobre el color del fondo y
  dibuja un degradado encima de sí misma para que el contenido se
  desvanezca al llegar a ella en vez de cortarse en seco. Ajustes se abre
  como página aparte tocando la foto de perfil de Inicio. El número de
  pendientes sale de un solo `StreamBuilder` en `ShellScreen`, que sirve
  al menú de PC y a la barra del celular.

El contenido lleva clave (`ValueKey('contenido')`) para que las pestañas no
pierdan su estado si la ventana cruza ese límite.

Las pantallas de configuración dibujan su `AppBar` con
`barraAjustes(context, título)`, que devuelve `null` cuando están dentro de
`SettingsScreen` (marcado con el `InheritedWidget` `AjustesEmbebido`) y una
barra normal cuando se abren sueltas.

Por dentro, las secciones usan las piezas de `ajustes_widgets.dart`:
`PaginaAjustes` (columna centrada de 760 px como máximo, con
`barraAjustes`), `TarjetaFilas` + `FilaAjuste` (una sola tarjeta con filas
de ícono, título, explicación y algo a la derecha; `FilaAjuste.interruptor`
para las de encender/apagar) y `AvisoDiscreto` (aviso informativo sin rojo,
igual que el del Plan de pago). Los formularios (Perfil, Correo) usan
`FormSection`/`CampoEtiquetado`/`FilaCampos` como los demás. Presupuestos
cruza `watchPresupuestos` con `GastosVariablesDao.watchTotalPorCategoria`
del mes en curso para dibujar lo gastado contra el límite.
`ConsejosNotificaciones` es público para poder probarlo (la pantalla de
celular llama al plugin de Android, que no existe en las pruebas).

`PerfilService` (nombre, apellido, foto) y `montosOcultosNotifier` /
`formatMonto` ("Ocultar montos": solo oculta Inicio, a propósito) viven en
`SharedPreferences`, se cargan en `main()` antes de `runApp` y se publican
con `ValueNotifier`.

### Estilo base (2026-11-11, plantilla de PC)

El aspecto sale de `AppTheme` y de unos pocos componentes compartidos; las
pantallas no deberían fijar radios ni bordes a mano.

- **Formas** (`AppSpacing`): tarjetas `radiusTarjeta` 24, campos
  `radiusCampo` 14, recuadros `radiusRecuadro` 16, ventanas `radiusDialogo`
  28, borde `borde` 1 px. Botones y etiquetas: `StadiumBorder`.
- **Tonos derivados** (`ValtiqColores`): `relieve` (campos, recuadros y
  pistas dentro de una tarjeta) y `acentoSuave` (fondo del cuadro de ícono).
  No son colores de la paleta: se calculan de `superficie`/`texto`/`acento`.
- **Encabezado de pantalla:** `EncabezadoPantalla(kicker, titulo, accion)`;
  el botón de crear es `BotonCrear` (píldora con texto en ancho ≥ 600,
  redondo con "+" en celular).
- **Pestañas:** `SelectorPildoras` (sobre el fondo). **Opciones dentro de
  una tarjeta:** `GrupoPildoras<T>`.
- **Formularios:** `PaginaFormulario` (columna centrada de 760 px máx.) →
  `FormSection` → `FilaCampos` → `CampoEtiquetado` (nombre encima del
  campo). Lo usan los formularios de deuda, préstamo, ingreso, gasto fijo
  gasto del día a día y recordatorio (todos los de datos).
- **Confirmaciones:** `confirmar(context, titulo, mensaje, accion,
  peligro)` (`utils/confirmar.dart`) en vez de `AlertDialog` a mano.
- **Listas de filas:** una sola `Card` con filas separadas por `Divider`
  fino (Pagadas, Cobrados, las tres listas de Finanzas), no una tarjeta
  por fila.
- **Limpiar historial:** `BotonLimpiarHistorial` va en la MISMA fila de las
  pestañas, a la derecha (solo ícono en celular).
- Colores y letras NO cambiaron (vino/negro/beige/morado, verde y rojo con
  su significado, Manrope + JetBrains Mono).

### Límites de lo que se puede escribir (2026-11-11)

- **Montos:** máximo 12 dígitos (`maxMonto`, `utils/currency_input.dart`).
  Los montos son `int` de 64 bits (tope real 9,2e18); con 12 dígitos por
  monto, ni las sumas ni los intereses se acercan. `CopInputFormatter`
  recorta y `parseCOP` devuelve `null` por encima.
- **Tasas:** máximo 500% (`maxTasa`, `utils/tasa_input.dart`). Con tasa > 0
  es obligatorio el tipo (mensual/anual); "ninguno" solo se guarda con
  tasa 0.
- **Resultados:** todo redondeo a pesos de un cálculo pasa por
  `InteresCalculator.aPesos` (acota a ±9e15; NaN → 0).

### Menú de PC: a la izquierda o arriba (2026-11-11)

`menuSuperiorNotifier` (preferencia `valtiq_menu_superior`) decide entre
`BarraLateral` y `BarraSuperior`. `ShellScreen` arma el cuerpo con un `Flex`
(horizontal o vertical) y el contenido lleva clave, así que cambiar la
posición —o cruzar el ancho de 900 px— no desmonta las pestañas.

### Borrar todo (2026-11-11)

`BorradoService.borrarTodo(db)`: vacía las 10 tablas en una transacción
(hijas primero), borra la foto de perfil, hace `prefs.clear()`, devuelve a
su valor de fábrica los notifiers en memoria (perfil, tema, ocultar montos,
menú, desbloqueo) y replanifica los avisos (queda todo cancelado). La clave
de cifrado del correo se conserva a propósito.

### Pantalla de Préstamos (2026-11-11)

Misma forma que Deudas. `PrestamosScreen` usa UN stream (join de préstamos
y pagos) y separa en Dart "Por cobrar" y "Cobrados".

- **Por cobrar:** totales "Te deben" y "Personas"; cuadrícula de tarjetas
  (iniciales, vencimiento, saldo, barra, botón "Registrar abono").
- **Cobrados:** una tarjeta con filas; "Limpiar historial" en la fila de
  pestañas (`PrestamosDao.deletePrestamosPagados`).
- **Detalle:** `PrestamoDetalleContenido` (en `prestamo_detalle.dart`). En
  ancho ≥ 800 va como panel de 440 px a la derecha (clave
  `panel-prestamo`); por debajo, `PrestamoDetalle` lo envuelve como página.
  `onSalir` cierra el panel / vuelve atrás cuando el préstamo deja la
  lista (cobrado, reactivado, eliminado).
- **Abonos:** `registrarAbonoPrestamo` + `RegistrarAbonoDialog`
  (`registrar_abono.dart`), compartido por la tarjeta y el detalle. Marca
  el préstamo como pagado si el abono lo deja en cero.
- `prestamo_widgets.dart`: `AvatarPersona`, `etiquetaTasaPrestamo`.

### Pantalla de Finanzas (2026-11-11)

Tres pestañas con la lógica de siempre (ingresos, gastos fijos y gastos
del día a día siguen separados, cada uno con su tabla, su DAO y su
formulario). Cada pestaña: totales sueltos arriba y una tarjeta con filas
(`_Fila`: ícono, nombre, detalle, monto y menú). El botón de crear del
encabezado cambia con la pestaña. Día a día sigue siendo UNA sola lista
desplazable (totales + selector de mes + "Por categoría" + gastos).

### Pantalla de Recordatorios (2026-11-11)

`RecordatoriosScreen` usa UN stream con todos los recordatorios y separa en
Dart "Activos" e "Inactivos" (antes un botón "Ver inactivos" y una consulta
por pestaña). El rótulo del encabezado cuenta los pendientes con la misma
regla que la insignia del menú (`ShellScreen._recordatoriosPendientes`):
vencidos o ya dentro de sus días de anticipación — la cuenta la hace
`_Tiempo`.

Cada recordatorio es una tarjeta: recuadro con día y mes (aro rojo si está
vencido, vino si ya está cerca), título, etiqueta con cuánto falta, de qué
es / si se repite / hora, y menú (Editar, Probar notificación, Inactivar o
Activar, Eliminar). "Vaciar inactivos" va en la fila de las pestañas, a la
derecha (`BotonLimpiarHistorial(texto: …)`). La lógica (DAO, deduplicación
al reactivar, prueba de notificación) no cambió.

### Plan de pago: aviso de pago mínimo (2026-11-11)

Si alguna deuda activa no tiene `cuotaMensual`, `PlanPagoTab` muestra un
aviso (clave `plan-sin-minimo`) con un botón por deuda. El botón abre
`DeudaForm(irAPagoMinimo: true)`, que baja hasta el campo, lo resalta
1,6 s y le pone el cursor.

### Pantalla de Deudas (2026-11-11)

`screens/deudas/`:

- `deudas_screen.dart` — encabezado ("Deudas" + "N activas"), selector de
  tres pestañas (`SelectorPildoras`, el mismo de Ajustes) y:
  - **Activas:** tres totales (`TotalesDeudas`: total de las deudas, pagos
    mínimos al mes, % pagado del total) y una cuadrícula de tarjetas de 1, 2
    o 3 columnas según el ancho. Cada tarjeta: `ImagenDeuda` (por ahora un
    ícono según `tipo`; ahí irá la galería de imágenes), nombre, descripción,
    etiqueta con la tasa, saldo, barra de avance, "N% de $total" y "Vence".
  - **Plan de pago:** `plan_pago_tab.dart`.
  - **Pagadas:** nombre, "descripción · Liquidada mes año" y lo pagado.
- `deuda_detalle.dart` — `DeudaDetalleContenido` es la tarjeta completa
  (saldo, cuatro recuadros: tasa, pago mínimo, próximo pago, liquidación
  estimada; pagos recientes; "Registrar pago"; "¿Cómo se calculó?"; "Más
  información"). Se usa de dos formas: como **panel a la derecha** cuando el
  área de Deudas mide ≥ 800 px (`DeudasScreen.anchoMinimoPanel`), o dentro de
  la página `DeudaDetalle` en celular. Editar, marcar como pagada/reactivar y
  eliminar están en su encabezado.
- `registrar_pago_dialog.dart` — ventana pequeña centrada: a qué deuda se
  abona y su saldo, monto (solo dígitos, mayor a 0, sin pasar del saldo) y
  dos atajos que llenan el monto: "Mínimo" y "Liquidar".
- `deuda_form.dart` — además de lo anterior: descripción, tipo y día de pago.

Los montos de Deudas usan `formatCOP`: "Ocultar montos" **no** los oculta
(decisión del 2026-11-11: solo oculta Inicio).

**Cálculos** (`services/deudas_calculos.dart`, puro, con tests en
`test/services/deudas_calculos_test.dart`). Todo parte de
`InteresCalculator.resumenPrestamo`, así que la tarjeta, el detalle y el plan
nunca muestran cifras distintas:

- `ResumenDeuda`: saldo, abonado, total, fracción pagada, pago mínimo (la
  cuota, sin pasarse del saldo) y:
  - `proximoPago(hoy)`: el siguiente día `diaPago` del calendario (si el mes
    no lo tiene, su último día).
  - `ritmoMensual(hoy)`: promedio de lo abonado en los últimos meses
    calendario completos (hasta 3; no cuenta el mes en curso ni el mes en que
    empezó la deuda). Sin historial, o si no se abonó nada, se usa la cuota.
  - `liquidacionEstimada(hoy)`: simula mes a mes (interés del mes, luego el
    pago al ritmo actual) hasta saldo cero. Por eso pagar de más adelanta la
    fecha y pagar de menos o saltarse un mes la atrasa. Si el pago no cubre
    el interés devuelve `noBaja`. Tope: 600 meses.
  - `interesDelMes(k, saldo)`: respeta la configuración de la deuda
    (`saldo_insoluto`: sobre el saldo; `saldo_original` simple: sobre el
    monto original; `saldo_original` compuesto: sobre el original
    capitalizado). Aproximación: en `saldo_insoluto` todo el saldo se toma
    como capital, así que con interés atrasado el estimado queda un poco por
    encima del real, nunca por debajo.
- `PlanPago.simular`: cada mes suma el interés de cada deuda, paga el mínimo
  de todas y manda lo que sobra (el "extra al mes" más los mínimos de las
  deudas ya terminadas) a la prioritaria. `EstrategiaPago.avalancha` ordena
  por tasa mensual más alta; `bolaDeNieve` por saldo más pequeño. Devuelve
  meses, fecha libre de deudas, intereses totales y el orden con la fecha de
  cada deuda. La estrategia y el extra se guardan en `SharedPreferences`
  (`valtiq_plan_estrategia`, `valtiq_plan_extra`).

### Widgets de Android y "Anotar gasto" (2026-11-12)

Decisión del usuario: el registro rápido es **solo por widget**; no hay
botón de registro rápido dentro de la app.

- **Tres widgets** (`android/app/src/main/kotlin/.../ResumenWidgets.kt`,
  con el paquete `home_widget`, licencia BSD, solo dependencias AndroidX):
  - `AnotarWidget`: tarjeta con un círculo vino con "+", "Anotar gasto" y
    "café 5000". Abre `AnotarActivity`.
  - `DeudasWidget` y `PrestamosWidget`: una fila del mismo tamaño que el
    de anotar (2×1): ícono en un aro, título y total de hoy con interés
    (sin nota desde 2026-11-14: no cabe). Al tocarlos abren
    Valtiq en esa sección (`valtiq://deudas` / `valtiq://prestamos`,
    `ShellScreen._abrirDesdeWidget`), con el bloqueo de siempre.
  - Diseños en `res/layout/widget_*.xml`, colores del tema en
    `res/values(-night)/colores_widget.xml`, íconos (los de Material de
    Inicio, en PNG blanco teñido) en `res/drawable-nodpi/`. Solo vistas que
    acepta `RemoteViews` (LinearLayout, ImageView, TextView): una `View`
    suelta hace que Android no deje agregar el widget.
  - **Versión compacta** (`widget_*_compacto.xml`): en Android 12+
    `vistaSegunAncho` le pasa a Android las dos versiones y él usa la
    compacta por debajo de `ANCHO_NORMAL` (180 dp), porque en el ancho
    mínimo el texto se cortaba. Ojo: a un `RemoteViews` hecho con mapa de
    tamaños no se le pueden poner textos después; se configuran las dos
    versiones antes de juntarlas. En Android 11 o antes solo existe la
    normal, con autoSize.
- **Datos de los widgets de resumen:** `WidgetsService` escucha
  `DashboardService.watchDeudasActivas/PrestamosActivos` (cada
  `CuentaActiva` sabe calcular su saldo en cualquier día) mientras la app
  está abierta y guarda, ya formateados, los totales de hoy y de los
  próximos `diasWidgetResumen` (90) días (`contenidoWidgetResumen`, probado
  sin Android): `{clave}_desde`, `{clave}_totales` (uno por renglón) y
  (hasta 2026-11-14 también `{clave}_nota`). El widget (`totalDeHoy` en Kotlin) elige el renglón de la
  fecha del celular, así que el interés avanza aunque no se abra Valtiq;
  como los pagos solo se registran dentro de Valtiq, que recalcula todo,
  esos números son los reales. Pasados los 90 días muestra "—" y pide
  abrir Valtiq. `updatePeriodMillis` = 1 h para cambiar de día (solo lee
  preferencias, no arranca Flutter). Por decisión del usuario estos
  widgets **no** se ocultan con el bloqueo con PIN (ponerlos es opcional).
- **"Anotar gasto":** `AnotarActivity` es un `FlutterActivity` aparte
  (tarea propia, fuera de recientes, fondo transparente) que corre
  `anotarMain()` de `main.dart`: su propia conexión a la base y solo
  `AnotarRapidoScreen`, sin splash ni bloqueo con PIN (decisión del
  usuario: solo agrega un gasto y no muestra nada de lo guardado). Para
  que se sienta rápido: el tema `AnotarTheme` oscurece el fondo con
  `backgroundDimEnabled` (sale al instante, antes que Flutter) y
  `anotarMain` llama a `runApp` sin esperar las categorías (la pantalla
  escucha `CategoriasService.lista`). Un
  renglón ("café 5mil"), vista previa de lo entendido, categoría
  propuesta en píldoras (se puede cambiar) y Guardar/Enter. Después:
  "Guardado", aviso si se pasó el presupuesto del mes, "Deshacer" y
  "Anotar otro"; se cierra sola a los 3 s. Sin nombre → "Sin nombre"; la
  fecha es hoy.
- **Lectura de la línea:** `utils/gasto_rapido.dart` (`leerGastoRapido`):
  5000, 5.000, 5,000, $5.000, 5mil, 5 mil, 5k, 5 lucas, 2,5 mil, 15 mil 500,
  1 millón, 2 palos, 2 millones 500 mil… y en letras (`_leerEnLetras`:
  "cincuenta mil pesos", "treinta y cinco mil", "mil quinientos", "dos
  millones quinientos mil"; solo si trae mil/millón o pesos/$, para que
  "dos empanadas" no sea un monto); con varios números gana el
  marcado como plata ($, mil, pesos) y si no el mayor. `leerListaGastos`
  ya lee listas enteras (para un "Pegar lista" futuro).
- **Categoría propuesta** (`categoriaPropuesta`): 1) la que se usó antes
  para ese nombre (`categoriaAprendida`, del historial: mismo nombre sin
  tildes/mayúsculas, o una palabra de 4+ letras en común); 2) la de la
  lista de nombres conocidos (`categoriaPorNombre`); 3) "Otros". Siempre
  una categoría que existe.
- **Al volver a la app** (`ShellScreen._alVolver`) se llama
  `markTablesUpdated([gastosVariables])`: lo anotado entró por otra
  conexión y las pantallas no se habrían enterado.

### Lista de nombres conocidos (2026-11-12)

`utils/nombres_conocidos.dart`: ~550 nombres de Colombia como **texto**
(sin logos: decisión tomada por derecho de autor/marcas y por F-Droid) en
grupos (bancos, billeteras, tarjetas de tiendas, financieras, cooperativas,
cajas de compensación, supermercados, tiendas, droguerías, ropa,
gasolineras, operadores, servicios públicos por ciudad, transporte, viajes,
suscripciones, restaurantes, salud, seguros, belleza, mascotas, giros y
apuestas, entretenimiento), con alias, categoría de gasto y tipo de deuda
por grupo, más ~140 palabras comunes ("café", "bus", "arriendo"). Usos:
- `CampoNombreConSugerencias` en el nombre de la deuda: sugiere al
  escribir y al elegir pone el tipo (y con él el ícono genérico).
- `categoriaPorNombre` para la primera categoría de un gasto rápido.
Para agregar un nombre basta sumarlo a su grupo; `nombres_conocidos_test`
revisa que no se repitan y que sus categorías existan.

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
`AppLifecycleState.hidden`/`paused` → `resumed` y volver a bloquear si pasó
más tiempo que `timeoutReloqueo` desde que la app quedó en segundo plano
(`paused` solo existe en Android/iOS; en Linux/Windows minimizar la ventana
llega como `hidden`. Perder el foco sin minimizar — `inactive` — no cuenta). El estado
inicial (`bloqueoInicial`) se calcula en `main()` ANTES de `runApp` — misma
convención que `themeModeNotifier` — para que el primer
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
cuota mensual fija dado un capital, tasa y número de cuotas. El
resultado se redondea a la centena de peso más cercana
(`_redondearACentena`, ej. 351.050 → 351.100) — una cuota sugerida con
sueltos de $1-$99 no es realista como cuota pactada, aunque implique
que la última cuota del crédito real quede un poco distinta.

**Desglose auditable del interés (2026-09-07):** `TramoInteres`
(clase pública en el mismo archivo) y `InteresCalculator.desglosePrestamo(...)`
devuelven, en vez de solo el total, la lista de tramos que lo componen
— cada uno con `capitalBase`, `mesesCompletos`, `diasParciales`,
`mesesTotal`, `tasaMensualPct` e `interes`. En `saldo_original` siempre
hay un único tramo (todo el préstamo corre sobre el mismo capital); en
`saldo_insoluto` hay un tramo por cada corte entre abonos, porque el
capital baja con cada uno — reutiliza exactamente el mismo recorrido
abono-a-abono que ya usaba `resumenPrestamo` (refactorizado a
`_procesarSaldoInsoluto`, que ahora calcula resumen y tramos a la vez
en un solo recorrido, para no arriesgar que las dos lógicas diverjan).
La convención de 30 días/mes para el prorrateo, antes solo interna
(`_diasPorMes`), ahora es la constante pública
`InteresCalculator.diasPorMesConvencion` para que la UI muestre
siempre el mismo número que usa el motor. Consumido por
`InteresDesgloseCard` (ver `utils/form_widgets.dart` más abajo), la
tarjeta "¿Cómo se calculó?" en `deuda_detalle.dart`/
`prestamo_detalle.dart` — solo se muestra si la deuda/préstamo tiene
tasa de interés > 0.

**NotificationService** (`services/notification_service.dart`)
Inicializa flutter_local_notifications en Linux, Android y Windows.
Ejecuta revisarRecordatorios() al arrancar o reanudar la app: evalúa
cada recordatorio activo, aplica deduplicación por frecuencia
(unica/diaria) y canal (sistema/correo), y dispara de inmediato
(`show()`) las notificaciones que correspondan. En Android, además,
`sincronizar()` deja los próximos avisos PROGRAMADOS en el sistema
(`zonedSchedule`, plan calculado por `NotificationPlanner`) para que
suenen a su hora con la app cerrada y tras reiniciar — ver
`docs/background-notifications-android.md`. En Linux/Windows no hay
scheduling: el aviso llega al abrir o volver a la app. Las referencias de deuda/préstamo/
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
- `utils/form_widgets.dart` — `InteresDesgloseCard` (2026-09-07):
  tarjeta expandible "¿Cómo se calculó?" que renderiza la lista de
  `TramoInteres` de `InteresCalculator.desglosePrestamo(...)` — fecha
  del tramo, fórmula (`capital × tasa% × meses`, o la variante
  compuesta), meses completos + días sobrantes, la división por
  `diasPorMesConvencion` y el resultado en dinero. Compartida entre
  `deuda_detalle.dart` y `prestamo_detalle.dart`.

## Flujo de datos

main() abre `AppDatabase` → carga SharedPreferences (tema, acento) →
`CryptoService.init()` → `NotificationService.init()` +
`revisarRecordatorios()` + `revisarIngresosUnicosVencidos()` (estas dos
sin `await`, fire-and-forget) → carga `bloqueoInicial`
(`AppLockService.bloqueoActivo()`) → `runApp` con `MaterialApp.builder`
envolviendo todo en `AppLockOverlay` → `home: SplashScreen` → tras
500ms, `ShellScreen` (menú lateral en PC, `BarraInferior` en
celular; ahí sí avisa con
SnackBar/diálogo si `claveFueRegenerada` o `ingresosUnicosDesactivados`
tienen algo pendiente) → pantallas acceden a `AppDatabase` vía
constructor. **DESPUÉS de `runApp`** (2026-09-04): se llama sin
esperar (`unawaited`) a `NotificationService.solicitarPermisoNotificaciones()`
— en Android eso espera la respuesta real del diálogo nativo de
permisos (13+), y correrlo antes de `runApp` bloqueaba el primer frame
hasta que el usuario respondiera. `SplashScreen` bajó su timer fijo de
2s a 500ms: para cuando esa pantalla se pinta, todo el async real de
arriba ya terminó, así que el delay era puramente decorativo.

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
