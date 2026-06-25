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
futuras con AndroidScheduleMode.inexact.

**SmtpService** (`services/smtp_service.dart`)
Envía correos usando mailer con la configuración de ConfigSmtps.
La contraseña se desencripta en memoria antes de cada envío.

**CryptoService** (`services/crypto_service.dart`)
Encripta y desencripta la contraseña SMTP con AES-256-CBC.
La clave se genera al primer uso y se persiste en valtiq_key.bin
fuera de la base de datos.

## Flujo de datos

main() carga SharedPreferences (tema, acento) →
SplashScreen abre AppDatabase →
NotificationService.init() + revisarRecordatorios() →
Shell con BottomNavigationBar →
pantallas acceden a AppDatabase vía constructor.

Los streams de drift (watchAll, watchActivos) mantienen las
listas reactivas: cualquier insert/update/delete reconstruye
automáticamente los widgets suscritos.

### Comparativo mensual de gastos variables

La card `_ComparativoCategorias` del Dashboard compara el mes actual
contra el mes anterior usando dos streams de `watchTotalPorCategoria`.
Genera una frase resumen del total (más/menos que el mes pasado) y una
línea por cada categoría donde la diferencia sea distinta de cero.
Si no hay datos del mes actual muestra un mensaje invitando a registrar
gastos; si no hay datos del mes anterior avisa que aún no hay histórico
para comparar.
