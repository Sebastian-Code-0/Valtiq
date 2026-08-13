# Arquitectura de Valtiq

## Base de datos (SQLite vía drift, schemaVersion 8)

### Tablas

**Deudas** — deudas propias del usuario
| Columna        | Tipo     | Notas                           |
|----------------|----------|---------------------------------|
| id             | INTEGER  | PK autoincrement                |
| acreedorNombre | TEXT     |                                 |
| montoOriginal  | REAL     |                                 |
| tasaInteres    | REAL     | default 0                       |
| tipoInteres      | TEXT     | 'ninguno' / 'mensual' / 'anual'          |
| modalidadCalculo | TEXT     | 'simple' / 'compuesto', default 'simple' |
| fechaPrestamo  | DATETIME |                                 |
| fechaLimite    | DATETIME | nullable                        |
| cuotaMensual   | REAL     | nullable                        |
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
| montoAbonado | REAL     |                  |
| fechaPago    | DATETIME |                  |
| notas        | TEXT     | default ''       |
| creadoEn     | DATETIME | default now      |

**Prestamos** — préstamos otorgados por el usuario
| Columna          | Tipo     | Notas                           |
|------------------|----------|---------------------------------|
| id               | INTEGER  | PK autoincrement                |
| deudorNombre     | TEXT     |                                 |
| deudorContacto   | TEXT     | default ''                      |
| montoPrestado    | REAL     |                                 |
| tasaInteres      | REAL     | default 0                       |
| tipoInteres      | TEXT     | 'ninguno' / 'mensual' / 'anual' |
| modalidadCalculo | TEXT     | 'simple' / 'compuesto'          |
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
| montoAbonado | REAL     |                     |
| fechaPago    | DATETIME |                     |
| notas        | TEXT     | default ''          |
| creadoEn     | DATETIME | default now         |

**Ingresos**
| Columna       | Tipo     | Notas                               |
|---------------|----------|-------------------------------------|
| id            | INTEGER  | PK autoincrement                    |
| concepto      | TEXT     |                                     |
| monto         | REAL     |                                     |
| frecuencia    | TEXT     | 'mensual' / 'quincenal' / 'semanal' |
| fecha         | DATETIME |                                     |
| notas         | TEXT     | default ''                          |
| activo        | BOOLEAN  | default true                        |
| creadoEn      | DATETIME | default now                         |
| actualizadoEn | DATETIME | default now                         |

**GastosFijos**
| Columna       | Tipo     | Notas                               |
|---------------|----------|-------------------------------------|
| id            | INTEGER  | PK autoincrement                    |
| concepto      | TEXT     |                                     |
| monto         | REAL     |                                     |
| frecuencia    | TEXT     | 'mensual' / 'quincenal' / 'semanal' |
| diaCobro      | INTEGER  | nullable                            |
| notas         | TEXT     | default ''                          |
| activo        | BOOLEAN  | default true                        |
| creadoEn      | DATETIME | default now                         |
| actualizadoEn | DATETIME | default now                         |

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
| monto       | REAL     |                  |
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

### Migraciones
- v1 → v2: crear ConfigSmtps, insertar fila id=1
- v2 → v3: migrar contrasena a tieneContrasena; crear PagosDeuda
- v3 → v4: agregar ConfigSmtps.contrasenaEncriptada
- v4 → v5: agregar Recordatorios.frecuenciaAviso,
           ultimaNotificacion, ultimoEnvioCorreo
- v5 → v6: agregar Recordatorios.horaAviso, minutoAviso
- v6 → v7: crear GastosVariables
- v7 → v8: añadir Deudas.modalidadCalculo (default 'simple')

### Ubicación de archivos

`valtiq.db` y `valtiq_key.bin` se guardan fuera del árbol de código.
En Android usan `getApplicationDocumentsDirectory()` (directorio
privado de la app, ya usado por instalaciones existentes). En
Linux/Windows usan `getApplicationSupportDirectory()`: la carpeta de
Documentos del usuario no es apropiada para archivos internos de la
app. En Android, `allowBackup="false"` en AndroidManifest.xml impide
que Auto Backup/`adb backup` extraiga `valtiq.db` y `valtiq_key.bin`
juntos (lo que permitiría desencriptar la contraseña SMTP fuera del
dispositivo).

## Pantallas

| Pantalla      | Archivo                   | Descripción                           |
|---------------|---------------------------|---------------------------------------|
| Dashboard     | dashboard_screen.dart     | Resumen financiero con saldos reales  |
| Deudas        | deudas_screen.dart        | Lista con saldo pendiente por deuda   |
| Préstamos     | prestamos_screen.dart     | Lista con saldo pendiente por préstamo|
| Finanzas      | finanzas_screen.dart      | Ingresos, gastos fijos y variables    |
| Recordatorios | recordatorios_screen.dart | Lista y gestión de recordatorios      |
| Ajustes       | settings_screen.dart      | Navegación a sub-pantallas            |
| Apariencia    | apariencia_screen.dart    | Tema claro/oscuro y color de acento   |
| Config SMTP   | config_smtp_screen.dart   | Configuración de correo saliente      |
| Acerca de     | acerca_de_screen.dart     | Versión, licencia y repositorio       |

## Servicios

**InteresCalculator** (`services/interes_calculator.dart`)
Cálculo de interés simple y compuesto por meses calendario.
La unidad base es el mes contado por límites reales del calendario,
no días fijos. Los días parciales del mes en curso se prorratean
sobre 30 días. Aplica convención bancaria colombiana para préstamos
que inician los días 29, 30 o 31: si el mes destino tiene menos
días, el aniversario cae en el último día de ese mes (no se
desborda al mes siguiente). Usado en dashboard, listas y detalles
de préstamos y deudas.

**NotificationService** (`services/notification_service.dart`)
Inicializa flutter_local_notifications en Linux, Android y Windows.
Ejecuta revisarRecordatorios() al arrancar la app: evalúa cada
recordatorio activo, aplica deduplicación por frecuencia
(unica/diaria) y canal (sistema/correo), y dispara las
notificaciones que correspondan. En Android programa notificaciones
futuras con AndroidScheduleMode.inexact. Las referencias de
deuda/préstamo/gasto de los recordatorios se cargan en batch (no una
query por recordatorio).

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
fallo en vez de crashear. La clave se genera al primer uso y se
persiste en valtiq_key.bin junto a la base de datos (ver
"Ubicación de archivos" arriba).

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

`RecordatoriosDao` expone `reactivarRecordatoriosPorReferencia`
(reactiva y resetea `ultimaNotificacion`/`ultimoEnvioCorreo` para que
vuelva a notificar limpio) y `eliminarRecordatoriosInactivos`
(borrado masivo, usado por el botón "vaciar inactivos" en la vista
de inactivos). El borrado de deudas/préstamos con pagos asociados es
transaccional y respeta integridad referencial (FK enforcement).

## Utilidades compartidas

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
  llevaría a un mes concreto), `BarraCategoria` (barra proporcional
  por categoría) y `BarraCategoriaComparada` (dos mini-barras
  apiladas + insignia de variación entre dos meses), ambas apoyadas
  en el widget privado compartido `_PistaBarra`, que anima el
  crecimiento del ancho con `TweenAnimationBuilder` (600ms,
  `Curves.easeOutCubic`) cada vez que cambia `fraccion`.
- `utils/categoria_gasto.dart` — `CategoriaGasto`, origen único de
  nombre+ícono+color por categoría de gasto variable, con fallback a
  "otros" para valores libres no listados. El color es fijo por
  categoría (independiente del acento personalizable y de
  `AppColors.alerta`) y se usa en las barras de Finanzas Variables y
  del comparativo del Dashboard.
- `theme/app_chip.dart` — `AppChip` y `AtenuableCard`, reemplazan
  chips y el patrón `Opacity(0.6)` duplicados en varias pantallas.

## Flujo de datos

main() carga SharedPreferences (tema, acento) →
SplashScreen abre AppDatabase →
NotificationService.init() + revisarRecordatorios() →
Shell con BottomNavigationBar →
pantallas acceden a AppDatabase vía constructor.

Los streams de drift (watchAll, watchActivos) mantienen las
listas reactivas: cualquier insert/update/delete reconstruye
automáticamente los widgets suscritos.

El Shell de navegación no anima el cambio de pestaña con fade
(se quitó: reconstruía las 5 pantallas en cada cambio).

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
`↑ ×20` por encima). Si no hay datos del mes B o del mes A, el método
`_estadoVacio` muestra un ícono de calendario + "Sin gastos en
{mes}" + texto secundario invitando a registrar o avisando que no hay
histórico para comparar. Todo el bloque de resumen/estado
vacío/barras está envuelto en un `AnimatedSwitcher` (400ms) con
`key: ValueKey('$_mesA-$_mesB')`; los dos `SelectorMes` y el título
quedan fuera.
