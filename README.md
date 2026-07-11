# Valtiq

Gestor de finanzas personales multiplataforma — Linux, Android y Windows.

Aplicación de código abierto (GNU GPLv3) para gestionar deudas, préstamos,
ingresos y gastos. Todos los datos se almacenan localmente en SQLite —
sin servidores, sin nube, sin cuentas de usuario.

## Qué hace

- Registro de préstamos otorgados, con interés simple y compuesto
  (convención bancaria colombiana para días 29-31)
- Registro de deudas propias con seguimiento de abonos
- Ingresos, gastos fijos y gastos variables por categoría
- Dashboard con balance real: Ingresos − Gastos Fijos − Gastos Variables
- Comparativo mensual de gastos variables por categoría
- Recordatorios de pago con notificación del sistema y/o correo SMTP
- Tema claro/oscuro con color de acento personalizable
- Credenciales SMTP cifradas localmente con AES-256

## Stack

| Componente     | Tecnología                          |
|----------------|--------------------------------------|
| Framework      | Flutter 3.32.1 / Dart                |
| Base de datos  | SQLite vía drift ORM (schemaVersion 8) |
| Notificaciones | flutter_local_notifications          |
| Correo         | mailer + encrypt (AES-256)           |
| Plataformas    | Linux, Android (API 21+), Windows    |

## Estructura del proyecto

```
lib/
  db/            # tablas drift, migraciones, DAOs
  screens/       # dashboard, deudas, préstamos, finanzas, recordatorios, ajustes
  services/      # NotificationService, SmtpService, InteresCalculator, CryptoService
  theme/         # AppColors, AppTheme, AppSpacing, AppTypography
  utils/         # formateo COP, fechas, widgets de formulario
docs/
  ARCHITECTURE.md   # esquema de BD y flujo de datos
  CHANGELOG.md      # historial de cambios por fase
  ANDROID.md / WINDOWS.md
  decisions/         # Architecture Decision Records (ADRs)
```

## Compilar

```bash
flutter build apk --debug   # Android, pruebas en dispositivo
flutter build linux          # Linux
flutter build windows        # Windows (requiere Visual Studio)
```

## Licencia

GNU General Public License v3.0. Ver [LICENSE](LICENSE).
