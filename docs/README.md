# Valtiq

Gestor de finanzas personales multiplataforma — Linux, Android y Windows.
Licencia: GNU GPL v3.0.

## Qué hace

Valtiq permite gestionar préstamos personales (como prestamista),
deudas propias, ingresos, gastos fijos y recordatorios de pago.
Todo se almacena localmente en SQLite — sin servidores, sin nube,
sin cuentas de usuario.

Funcionalidades principales:
- Registro de préstamos con cálculo de interés simple y compuesto
- Registro de deudas propias con seguimiento de abonos
- Dashboard con saldo real (capital + interés acumulado − abonos)
- Ingresos y gastos fijos con proyección mensual
- Recordatorios con notificación por sistema operativo y/o correo SMTP
- Tema claro/oscuro y color de acento personalizable
- Correo SMTP con encriptación AES-256 de la contraseña

## Stack

| Componente     | Tecnología                        |
|----------------|-----------------------------------|
| Framework      | Flutter 3.32.1 / Dart             |
| Base de datos  | SQLite vía drift ORM              |
| Notificaciones | flutter_local_notifications       |
| Correo         | mailer + encrypt (AES-256)        |
| Plataformas    | Linux, Android (API 21+), Windows |

## Estructura del proyecto

```
lib/
  db/
    tables.dart          # 8 tablas drift
    database.dart        # AppDatabase, migraciones (schemaVersion 6)
    daos/                # 7 DAOs con queries reactivas
  screens/               # 9 pantallas + shell de navegación
  services/              # NotificationService, SmtpService,
                         # InteresCalculator, CryptoService
  theme/                 # AppColors, AppTheme, AppSpacing,
                         # AppTypography
  utils/                 # Formateo COP, fechas, widgets de formulario
docs/
  decisions/             # Architecture Decision Records (ADRs)
  ANDROID.md             # Guía de compilación Android
  WINDOWS.md             # Guía de compilación Windows
  ARCHITECTURE.md        # Esquema de BD y flujo de datos
  CHANGELOG.md           # Historial de cambios por fase
```

## Compilar

```bash
# Android (debug para pruebas en dispositivo)
flutter build apk --debug

# Linux
flutter build linux

# Windows (requiere entorno Windows con Visual Studio)
flutter build windows
```

## Licencia

GNU General Public License v3.0.
Código fuente: https://github.com/Sebastian-Code-0/Valtiq
