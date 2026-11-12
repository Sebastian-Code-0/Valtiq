# Valtiq

Gestor de finanzas personales multiplataforma — Linux, Android y Windows.

Aplicación de código abierto (GNU GPLv3) para gestionar deudas, préstamos,
ingresos y gastos. Todos los datos se almacenan localmente en SQLite —
sin servidores, sin nube, sin cuentas de usuario.

## Qué hace

- Registro de préstamos otorgados, con interés simple y compuesto
  (convención bancaria colombiana para días 29-31) y abonos rápidos
- Registro de deudas propias con seguimiento de abonos y plan de pago
  (avalancha o bola de nieve) que estima cuándo se queda libre de deudas
- Desglose auditable del interés ("¿Cómo se calculó?") y guía integrada
  ("Cómo funciona Valtiq") que explica cada cálculo en lenguaje simple
- Ingresos, gastos fijos y gastos del día a día por categoría, con
  presupuestos mensuales
- Inicio con balance real: Ingresos − Gastos fijos − Gastos del día a día
- Comparativo mensual de gastos del día a día por categoría
- Recordatorios de pago con notificación del sistema (en Android llegan a su hora aunque la app esté cerrada) y/o correo SMTP
- Bloqueo de la app con PIN o biometría (opcional, desactivado por defecto)
- Tema claro/oscuro; en pantallas grandes, menú a la izquierda o arriba
- Copia de seguridad en un archivo y opción de borrar todo
- Credenciales SMTP cifradas localmente con AES-256

## Stack

| Componente     | Tecnología                          |
|----------------|--------------------------------------|
| Framework      | Flutter 3.32.1 / Dart                |
| Base de datos  | SQLite vía drift ORM (schemaVersion 14) |
| Notificaciones | flutter_local_notifications          |
| Correo         | mailer + encrypt (AES-256)           |
| Seguridad      | local_auth (biometría) + PIN propio (SHA-256 con salt) |
| Plataformas    | Linux, Android (API 23+), Windows    |

## Estructura del proyecto

```
lib/
  db/            # tablas drift, migraciones, DAOs
  screens/       # inicio (dashboard), deudas, préstamos, finanzas, recordatorios, ajustes
  services/      # NotificationService, SmtpService, InteresCalculator, CryptoService, AppLockService, BackupService, BorradoService
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

## Privacidad

Valtiq no recolecta ni transmite datos. Ver la
[política de privacidad](docs/PRIVACY.md) completa.

## Licencia

GNU General Public License v3.0. Ver [LICENSE](LICENSE).

Las fuentes Manrope y JetBrains Mono incluidas en `assets/fonts/` usan la
SIL Open Font License 1.1 (texto junto a cada fuente).
