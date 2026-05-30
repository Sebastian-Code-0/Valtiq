# Android — Guía de compilación e instalación

## Requisitos previos

- Flutter 3.32.1 o superior
- Android SDK (API 21+) instalado y configurado en `android/local.properties`:
  ```
  sdk.dir=/ruta/a/tu/android/sdk
  flutter.sdk=/opt/flutter
  ```
- JDK 11 o superior

## Build e instalación

```bash
# APK debug (para pruebas directas en dispositivo/emulador)
flutter build apk --debug

# APK release (requiere configurar signing en build.gradle.kts)
flutter build apk --release

# Instalar directamente en dispositivo conectado
flutter install

# Ejecutar en dispositivo/emulador conectado
flutter run
```

El APK de debug se genera en: `build/app/outputs/flutter-apk/app-debug.apk`

## Versiones SDK

| Parámetro | Valor |
|-----------|-------|
| `minSdkVersion` | 21 (Android 5.0 Lollipop) |
| `compileSdk` | `flutter.compileSdkVersion` (35 en Flutter 3.32) |
| `targetSdk` | `flutter.targetSdkVersion` (35 en Flutter 3.32) |

El `minSdk = 21` es el valor por defecto de Flutter y cumple el requisito de `flutter_local_notifications`.

## Permisos declarados

| Permiso | Motivo |
|---------|--------|
| `INTERNET` | Envío de correos SMTP |
| `POST_NOTIFICATIONS` | Notificaciones del SO (Android 13+) |

En Android 13+ (API 33), el sistema muestra un diálogo pidiendo permiso de notificaciones la primera vez que se inicializa la app.

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
