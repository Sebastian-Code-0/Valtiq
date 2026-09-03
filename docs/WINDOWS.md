# Valtiq — Compilación y ejecución en Windows

## Requisitos

- **Windows 10 versión 1903 o superior** (necesario para las notificaciones toast)
- **Visual Studio 2022** con el componente "Desarrollo para escritorio con C++"
  - Incluye: MSVC v143, Windows 10/11 SDK, CMake
- **Flutter 3.32.1 o superior** configurado para Windows (`flutter config --enable-windows-desktop`)
- **Git for Windows**

## Compilar

```powershell
flutter pub get
flutter build windows --debug     # debug
flutter build windows --release   # release
```

El ejecutable queda en `build\windows\x64\runner\Release\valtiq.exe`.

## Diferencias de comportamiento respecto a Linux

| Aspecto | Linux | Windows |
|---------|-------|---------|
| Notificaciones del SO | D-Bus / libnotify | Windows Toast API |
| Ruta de datos de la app | `$HOME/.local/share` | `%APPDATA%\Roaming` |
| Ruta de documentos | `$HOME/Documents` | `%USERPROFILE%\Documents` |
| Clave de cifrado (`valtiq_key.bin`) | `Documents/valtiq_key.bin` | `Documents\valtiq_key.bin` |
| Base de datos SQLite | `Documents/valtiq.db` | `Documents\valtiq.db` |

La llave de cifrado **no es portable** entre instalaciones. Si se copia la base de datos a otra máquina, las contraseñas SMTP guardadas no podrán descifrarse.

## Limitaciones conocidas de notificaciones en Windows

`flutter_local_notifications` soporta Windows con estas restricciones:

- **`show()`** — Funciona sin MSIX packaging. Las notificaciones aparecen en el Centro de actividades.
- **`cancel()`** — Requiere MSIX packaging para funcionar. Sin él, la llamada se ignora silenciosamente (el código ya envuelve esto en try-catch).
- **`getActiveNotifications()`** — Requiere MSIX packaging.
- **`periodicallyShow()` / `periodicallyShowWithDuration()`** — No soportadas en Windows; lanzan `UnsupportedError`. Valtiq no usa estos métodos.

### AUMID y GUID

La configuración actual usa:
- `appUserModelId`: `com.valtiq.Valtiq`
- `guid`: `a8b4c2d6-1e3f-4a5b-8c9d-0e2f7a6b3c1d`

Para distribución con MSIX, el AUMID debe coincidir con el declarado en el manifiesto del paquete.

## Empaquetado MSIX (distribución)

Para distribución en Microsoft Store o instalador con todas las funciones:

```powershell
flutter pub add msix --dev
flutter pub run msix:create
```

Esto requiere un certificado de firma de código. Para desarrollo local se puede usar un certificado autofirmado.

## Tamaño mínimo de ventana

La ventana tiene un mínimo de 800×600 px configurado en `windows/runner/win32_window.cpp`.

## Bloqueo de la app (PIN/biometría) en Windows

El bloqueo opcional de la app (Ajustes → Seguridad) usa `local_auth` para
ofrecer Windows Hello (huella, rostro o PIN del sistema) como método de
desbloqueo — requiere Windows 10 o superior. Según la documentación oficial
del paquete, no hace falta empaquetado MSIX ni ninguna capacidad de
manifiesto especial para esto (a diferencia de algunas funciones de
notificaciones, ver arriba). Una limitación documentada por el propio
paquete: en Windows no se puede forzar "solo biométrico" (`biometricOnly`)
porque la API de Windows Hello no soporta elegir el método de
autenticación — Valtiq ya pasa `biometricOnly: false` explícitamente, así
que esto no cambia el comportamiento esperado. Si el dispositivo no tiene
Windows Hello configurado, la app cae al PIN propio de Valtiq como
alternativa siempre disponible. **Sin verificar todavía en un dispositivo
Windows real** — esta sección se basa en la documentación del paquete, no
en una prueba directa.
