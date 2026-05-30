# Changelog

## 2026-05-30 — Fase 4: Soporte Android

- `notification_service.dart`: Agregar `TargetPlatform.android` a `_soportado`; rama `Platform.isAndroid` en `init()` con `AndroidInitializationSettings('@mipmap/ic_launcher')` y solicitud de permiso en Android 13+; rama en `showNotification()` con `AndroidNotificationDetails` (canal `valtiq_recordatorios`, importance/priority high)
- `android/app/src/main/AndroidManifest.xml`: Corregir `android:label` de `"valtiq"` a `"Valtiq"`; agregar permisos `INTERNET` y `POST_NOTIFICATIONS`
- `lib/screens/deudas/deuda_detalle.dart`: Reemplazar `SizedBox(width: 400)` por `SizedBox(width: double.maxFinite)` en diálogo de abono — evita overflow en pantallas móviles
- `lib/screens/prestamos/prestamo_detalle.dart`: Mismo cambio en diálogo de pago
- `docs/ANDROID.md`: Crear guía de compilación, diferencias vs desktop y limitaciones conocidas

## 2026-05-27 — Fase 3: Soporte Windows

- `notification_service.dart`: Ampliar `_soportado` a `TargetPlatform.windows`; agregar inicialización con `WindowsInitializationSettings` y detalles con `WindowsNotificationDetails`; envolver `cancel()` en try-catch por limitación sin MSIX
- `crypto_service.dart`: Reemplazar concatenación de path con `/` por `path.join()` para consistencia entre plataformas
- `windows/runner/main.cpp`: Capitalizar título de ventana `L"Valtiq"`
- `windows/runner/Runner.rc`: Capitalizar `FileDescription`, `InternalName` y `ProductName` a `"Valtiq"`
- `windows/runner/win32_window.cpp`: Agregar handler `WM_GETMINMAXINFO` con tamaño mínimo 800×600
- `docs/WINDOWS.md`: Crear guía de compilación, diferencias Linux/Windows y limitaciones de notificaciones

## 2026-05-22

- Fase 0 - Setup inicial del proyecto
