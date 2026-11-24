# Política de Privacidad de Valtiq

Última actualización: 24 de noviembre de 2026

## Resumen

Valtiq no recolecta, transmite ni comparte ningún dato personal. Toda la
información que ingreses (deudas, préstamos, ingresos, gastos, recordatorios)
se almacena únicamente en el dispositivo donde instalas la app, en una base
de datos SQLite local. No hay cuentas de usuario, no hay servidores de
Valtiq, y no se usa ningún servicio externo de analítica, publicidad o
rastreo.

## Qué datos almacena la app (localmente, en tu dispositivo)

- Deudas y pagos asociados
- Préstamos otorgados y pagos recibidos
- Ingresos y gastos (fijos y variables)
- Recordatorios de pago
- Configuración de correo SMTP (si decides usar la función de recordatorios
  por correo)
- Categorías de gasto que creas o cambias
- Preferencias de apariencia (tema, posición del menú)
- Si activas el bloqueo de la app (ver abajo): un hash con salt de tu PIN —
  nunca el PIN en sí

Ninguno de estos datos sale de tu dispositivo, salvo en el caso descrito
abajo (correo SMTP), y solo si tú activas esa función explícitamente.

## Función opcional: bloqueo con PIN o biometría

Valtiq permite, de forma opcional y desactivada por defecto, pedir PIN o
biometría (huella, rostro, o el PIN/patrón del sistema) cada vez que abres
la app.

- El PIN que elijas nunca se guarda en texto plano: se guarda un hash
  (SHA-256 con salt aleatorio, 10.000 iteraciones) del que no se puede
  recuperar el PIN original.
- La biometría la maneja el sistema operativo directamente (Android
  o Windows) a través del paquete oficial `local_auth`. Valtiq nunca
  recibe, procesa ni almacena tu huella dactilar, tu rostro ni ningún dato
  biométrico — solo recibe un resultado de "autenticado" o "no
  autenticado" desde el sistema operativo.
- Esta función es solo un candado de acceso a la app: no cifra ni protege
  de forma adicional los datos guardados en el dispositivo (para eso está
  el cifrado AES-256 de las credenciales SMTP, descrito abajo).

## Función opcional: widgets de la pantalla de inicio (Android)

Si pones un widget de Valtiq en tu pantalla de inicio:
- **Deudas activas / Prestado activo** muestran en la pantalla de inicio
  el total que debes o que te deben (sin nombres). Esos totales se guardan en el
  almacenamiento privado de la app para que Android pueda dibujar el
  widget; no salen del dispositivo. Cualquiera que vea tu pantalla de
  inicio los puede leer, aunque tengas el bloqueo con PIN activo: si no lo
  quieres así, no pongas esos widgets.
- **Anotar gasto** abre una ventanita para agregar un gasto **sin pedir el
  PIN** (a propósito, para que sea rápido). Solo permite agregar: no
  muestra nada de lo que ya tienes guardado.

## Función opcional: recordatorios por correo (SMTP)

Valtiq permite, de forma opcional, enviar recordatorios de pago por correo
electrónico usando un servidor SMTP que tú mismo configuras (por ejemplo,
tu propia cuenta de Gmail o cualquier proveedor de correo).

- Esta función está desactivada por defecto.
- Las credenciales SMTP que ingreses se cifran con AES-256 antes de
  guardarse en el dispositivo, usando una clave generada de forma aleatoria
  para tu instalación.
- Los correos se envían directamente desde tu dispositivo hacia tu propio
  servidor SMTP. Valtiq no tiene servidores propios y no intercepta,
  almacena ni tiene acceso a estos correos ni a tus credenciales.

## Perfil (nombre y foto)

Si escribes tu nombre o eliges una foto de perfil, se guardan únicamente en
tu dispositivo, dentro de la carpeta privada de Valtiq. No se envían a ningún
lado. Sí se incluyen en el archivo de copia de seguridad que tú exportas, para
que lleguen al importarlo en otro dispositivo.

## Permisos que solicita la app (Android)

- **Notificaciones (POST_NOTIFICATIONS)**: para mostrar recordatorios de
  pago dentro del dispositivo.
- **Iniciar al encender (RECEIVE_BOOT_COMPLETED)**: para volver a programar
  tus recordatorios después de reiniciar o encender el celular. No abre la
  app ni envía nada a ningún lado.
- **Alarmas y recordatorios (SCHEDULE_EXACT_ALARM)**: opcional. Solo se usa
  si activas "Avisar a la hora exacta"; sin él, tus avisos llegan igual, con
  unos minutos de margen.
- **Internet (INTERNET)**: usado únicamente si activas la función de
  recordatorios por correo SMTP, para conectarse al servidor que
  configuraste. Si no usas esa función, la app no realiza ninguna conexión
  de red.
- **Biometría (USE_BIOMETRIC)**: usado únicamente si activas el bloqueo
  de la app y eliges desbloquear con huella o rostro. Si no activas esa
  función, la app no accede al sensor biométrico.

Valtiq no solicita acceso a contactos, ubicación, cámara, almacenamiento
compartido, ni ningún otro permiso.

## Servicios de terceros

Valtiq no integra ningún SDK de analítica, publicidad, rastreo de
comportamiento ni servicios de terceros. El código fuente completo es
público y auditable bajo la licencia GNU GPLv3.

Las fuentes tipográficas (Manrope y JetBrains Mono, licencia SIL OFL 1.1)
van incluidas dentro de la aplicación: no se descargan de ningún servidor.

## Menores de edad

Valtiq no está dirigida a menores de 13 años y no recolecta
intencionalmente información de menores, dado que no recolecta información
de ningún usuario.

## Eliminación de datos

Como todos los datos viven únicamente en tu dispositivo, puedes eliminarlos
en cualquier momento:

- **Desde la app:** Ajustes → Copia de seguridad → "Borrar todo" elimina
  todos tus datos, tu perfil y tu foto, el PIN, el correo configurado y
  todos los ajustes, y cancela los avisos programados. La app queda como
  recién instalada. Pide confirmación (y el PIN, si lo tienes activo).
- **Por partes:** "Limpiar historial" (en Deudas → Pagadas y en Préstamos →
  Cobrados) elimina solo lo ya pagado, con sus pagos.
- **Desde el sistema:** desinstalando la aplicación o borrando sus datos
  desde la configuración del sistema operativo.

Valtiq no conserva copias en ningún otro lugar.

## Copias automáticas de Android

Valtiq excluye todos sus datos de las copias automáticas de Android: la copia
en la nube (Google) y la transferencia directa de un celular a otro al
configurar un dispositivo nuevo. Con `allowBackup="false"` solo no basta en
Android 12 o superior, porque en algunos fabricantes la transferencia entre
dispositivos sigue activa, así que además se declaran reglas explícitas en
`android/app/src/main/res/xml/data_extraction_rules.xml`.

El único respaldo soportado es el manual, desde Ajustes → Copia de
seguridad: tú decides dónde se guarda el archivo y quién tiene acceso a él.
El archivo no está cifrado: lleva tus datos, tu nombre, tu foto y la hora del
recordatorio diario, pero nunca el PIN, el bloqueo ni el correo configurado.
Al cambiar de celular debes exportar tus datos en el anterior e importarlos
en el nuevo.

## Cambios a esta política

Si esta política cambia (por ejemplo, al agregar una nueva función), se
actualizará este documento junto con la fecha de "Última actualización"
arriba, y el cambio quedará registrado en el historial de commits del
repositorio.

## Contacto

Para preguntas sobre esta política o el manejo de datos, puedes abrir un
issue en el repositorio:
https://github.com/Sebastian-Code-0/Valtiq/issues
