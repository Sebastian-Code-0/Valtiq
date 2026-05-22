# 001 - Elección del stack: Flutter

## Estado

Aceptada — 2026-05-22

## Contexto

Valtiq es una app de finanzas personales que debe funcionar tanto en escritorio (Linux y Windows) como en móvil (Android), almacenando datos sensibles del usuario localmente y sin requerir infraestructura externa.

## Decisión

Se eligió **Flutter** como framework principal para el desarrollo de Valtiq.

## Razones

### Multiplataforma desde una sola base de código

Flutter permite mantener un único codebase en Dart que compila nativamente a Linux, Android y Windows (además de iOS, macOS y web si en el futuro fuera necesario). Esto reduce el esfuerzo de mantenimiento y garantiza que la experiencia del usuario sea consistente en todas las plataformas soportadas.

### SQLite embebido

Mediante paquetes como `drift` y `sqlite3_flutter_libs`, Flutter integra SQLite de forma embebida en la aplicación. Esto encaja perfectamente con el modelo de Valtiq: los datos financieros del usuario viven en su dispositivo, en un archivo de base de datos local, sin necesidad de servidores ni sincronización por defecto.

### Sin dependencias externas para el usuario final

El binario resultante de Flutter es autocontenido: el usuario no necesita instalar runtimes adicionales (JVM, Node, Python, etc.) ni servicios de terceros. Esto simplifica la instalación, mejora la privacidad y permite que la app funcione completamente offline.

## Consecuencias

- Todo el equipo trabajará en Dart.
- Las decisiones de UI seguirán los lineamientos de Material/Flutter, adaptadas al contexto de cada plataforma cuando sea necesario.
- La capa de persistencia se construirá sobre `drift` y SQLite.
