# 002 - Base de datos: SQLite con drift

## Estado

Aceptada — 2026-05-22

## Contexto

Valtiq almacena datos financieros sensibles que deben vivir
exclusivamente en el dispositivo del usuario. Se necesitaba
persistencia local que funcione en Linux, Android y Windows
desde un único codebase en Dart.

## Alternativas consideradas

- sqflite directo: solo funciona en Android/iOS, no en desktop.
- Hive: NoSQL, sin soporte para queries relacionales ni
  migraciones formales.
- Isar: en fase beta para desktop en el momento de la decisión.
- SQLite con drift: type-safe, multiplataforma, streams
  reactivos, migraciones incrementales formales.

## Decisión

Se eligió drift como ORM sobre SQLite.

## Razones

- Type-safety en tiempo de compilación: las queries se validan
  en build, no en runtime.
- Streams reactivos: watchAll() y watchActivos() reconstruyen
  los widgets automáticamente ante cualquier cambio en la BD.
- Migraciones incrementales: MigrationStrategy con onUpgrade
  permite evolucionar el esquema de forma controlada.
- Multiplataforma: sqlite3_flutter_libs incluye SQLite en el
  binario para todas las plataformas soportadas.

## Consecuencias

- El archivo de BD vive en el directorio de datos de la app
  (path_provider). No accesible sin root en Android.
- Las migraciones son selladas: una vez que una versión llega
  a main, no se puede modificar — solo incrementar
  schemaVersion y agregar un nuevo bloque if (from < N).
- drift_dev y build_runner son requeridos para regenerar
  los archivos .g.dart tras cambios en tablas o DAOs.
