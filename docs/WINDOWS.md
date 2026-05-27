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
