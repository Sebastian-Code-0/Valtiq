# Changelog

## 2026-05-27 — Fase 3: Soporte Windows

- `notification_service.dart`: Ampliar `_soportado` a `TargetPlatform.windows`; agregar inicialización con `WindowsInitializationSettings` y detalles con `WindowsNotificationDetails`; envolver `cancel()` en try-catch por limitación sin MSIX
- `crypto_service.dart`: Reemplazar concatenación de path con `/` por `path.join()` para consistencia entre plataformas
- `windows/runner/main.cpp`: Capitalizar título de ventana `L"Valtiq"`
- `windows/runner/Runner.rc`: Capitalizar `FileDescription`, `InternalName` y `ProductName` a `"Valtiq"`
- `windows/runner/win32_window.cpp`: Agregar handler `WM_GETMINMAXINFO` con tamaño mínimo 800×600
- `docs/WINDOWS.md`: Crear guía de compilación, diferencias Linux/Windows y limitaciones de notificaciones

## 2026-05-22

- Fase 0 - Setup inicial del proyecto
