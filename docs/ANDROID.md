# Android — Guía de compilación e instalación

## Requisitos previos

- Flutter 3.32.1 o superior
- Android SDK (API 23+) instalado y configurado en `android/local.properties`:
  ```
  sdk.dir=/ruta/a/tu/android/sdk
  flutter.sdk=/opt/flutter
  ```
- JDK 11 o superior

## Build e instalación

```bash
# APK debug (para pruebas directas en dispositivo/emulador)
flutter build apk --debug

# APK release (requiere android/key.properties, ver abajo)
flutter build apk --release

# Instalar directamente en dispositivo conectado
flutter install

# Ejecutar en dispositivo/emulador conectado
flutter run
```

El APK de debug se genera en: `build/app/outputs/flutter-apk/app-debug.apk`

## Splash nativo

El proyecto usa `flutter_native_splash` (configurado en el bloque
`flutter_native_splash:` de `pubspec.yaml`) para el splash nativo de
Android, en vez del blanco por defecto de Flutter. Después de correr
`flutter pub get` — o cada vez que cambie la config de
`flutter_native_splash` en `pubspec.yaml` — hay que regenerar los
recursos nativos una vez:

```bash
dart run flutter_native_splash:create
```

Esto reescribe `android/app/src/main/res/drawable*/` y
`values*/styles.xml` con el color e imagen configurados. No es un paso
automático de `flutter pub get` ni de `flutter build`.

## Firma de release

`android/app/build.gradle.kts` define `signingConfigs.release` leyendo
credenciales desde `android/key.properties` (no versionado, no existe
en el repo):
```
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/ruta/al/keystore.jks
```
Sin ese archivo, `flutter build apk --release` falla al resolver
`keystoreProperties["..."]`. El keystore y `key.properties` se
generan y guardan fuera del repo, solo en la máquina que compila el
release.

## Versiones SDK

| Parámetro | Valor |
|-----------|-------|
| `minSdkVersion` | 23 (Android 6.0 Marshmallow) — forzado en `build.gradle.kts` (`maxOf(flutter.minSdkVersion, 23)`) |
| `compileSdk` | 36 — forzado (`maxOf(flutter.compileSdkVersion, 36)`) |
| `targetSdk` | `flutter.targetSdkVersion` (el default de Flutter 3.32) |

El `minSdk` subió de 21 (default de Flutter) a 23 porque
`flutter_secure_storage` (usado para la clave AES en Keystore/Keychain,
ver `docs/ARCHITECTURE.md`) lo requiere. `compileSdk` subió a 36 porque
`flutter_secure_storage` compila contra ese SDK, por delante del default
de Flutter 3.32.

`MainActivity.kt` es `FlutterFragmentActivity` (no `FlutterActivity`):
`local_auth` necesita una `FragmentActivity` para mostrar el
`BiometricPrompt` nativo del bloqueo con PIN/biometría.

## Permisos declarados

| Permiso | Motivo |
|---------|--------|
| `INTERNET` | Envío de correos SMTP |
| `POST_NOTIFICATIONS` | Notificaciones del SO (Android 13+) |
| `USE_BIOMETRIC` | Bloqueo de la app con huella/rostro (opcional, desactivado por defecto) |

En Android 13+ (API 33), el sistema muestra un diálogo pidiendo permiso de notificaciones la primera vez que se inicializa la app. Ese diálogo se pide DESPUÉS de que la app ya se muestra (`NotificationService.solicitarPermisoNotificaciones()`, llamado sin esperar tras `runApp()` en `main.dart`) — pedirlo antes bloqueaba el primer frame hasta que el usuario respondiera (corregido 2026-09-04).

## Diferencias de comportamiento vs Linux/Windows

| Característica | Linux/Windows | Android |
|----------------|---------------|---------|
| Notificaciones | dbus / Toast API | Notification channel `valtiq_recordatorios` |
| Icono de notificación | N/A | `@mipmap/ic_launcher` |
| Canal de notificación | N/A | Se crea automáticamente con la primera notificación |
| Tamaño mínimo de ventana | 800×600 (Win32) | N/A (el SO controla el layout) |
| Botón "atrás" | N/A | Funciona con `Navigator.pop` estándar de Flutter |
| Teclado | N/A | `adjustResize` configurado en AndroidManifest |

## Limitaciones conocidas

- **Notificaciones programadas:** La app revisa recordatorios al inicio (`revisarRecordatorios()`). No hay notificaciones en segundo plano cuando la app está cerrada.
- **SMTP en Android:** Funciona sobre red móvil y WiFi. En redes corporativas con firewall puede haber bloqueos de puertos SMTP (465, 587).
- **Fuentes Google:** `google_fonts` descarga las fuentes la primera vez que la app se ejecuta con conexión a internet. Sin conexión usa el fallback del sistema.

## Estructura de archivos Android relevantes

```
android/
  app/
    src/main/
      AndroidManifest.xml   # Permisos e intents
      res/
        mipmap-*/           # Íconos de la app
    build.gradle.kts        # Configuración de compilación
  build.gradle.kts          # Configuración raíz Gradle
  settings.gradle.kts       # Plugins Gradle
```
