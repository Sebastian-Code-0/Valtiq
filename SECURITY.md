# Seguridad

Si encontraste un problema de seguridad en Valtiq (por ejemplo, una forma de
leer los datos de otra persona, saltarse el PIN o hacer que un archivo de
respaldo dañe la app), por favor **no lo publiques en un issue**.

Repórtalo en privado desde la pestaña **Security** de este repositorio, con
el botón **Report a vulnerability**. Solo el mantenedor puede leerlo.

Incluye, si puedes:

- Qué versión de Valtiq usas y en qué dispositivo (Android, Linux o Windows).
- Los pasos para reproducirlo.
- Qué puede lograr alguien que lo aproveche.

Valtiq es un proyecto de una sola persona: la respuesta puede tardar unos
días, pero todo reporte se revisa. Cuando el arreglo esté publicado, el
problema se describirá en el [CHANGELOG](docs/CHANGELOG.md).

## Qué cubre

Valtiq no tiene servidores: todos los datos viven en tu dispositivo. Lo más
importante es lo que protege esos datos: el bloqueo con PIN o biometría, el
cifrado de la contraseña del correo, la copia de seguridad y la importación
de archivos.
