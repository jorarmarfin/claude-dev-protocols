# tech.md — Arquitectura técnica

**Proyecto:** {{PROJECT_NAME}} · **Stack:** {{STACK}} · **Última actualización:** {{DATE}}

## 1. Overview

{{OVERVIEW}}

## 2. Stack local

| Servicio | Imagen/base | Rol |
|---|---|---|
| db | mariadb:${MARIADB_VERSION} | Base de datos |
| php | build local (docker/php) | PHP-FPM {{PHP_VERSION}} |
| nginx | nginx:1.27-alpine | Servidor web + TLS local |
| {{CLI_SERVICE}} | build local (docker/php) | CLI de administración |

## 3. Diferencias con producción

| Aspecto | Local | Producción |
|---|---|---|
| Dominio | `{{PROJECT_NAME}}.localhost` (TLS mkcert) | (completar) |
| Base de datos | MariaDB ${MARIADB_VERSION} | (completar motor/versión real) |
| Contenido | Instalación limpia / dump en `sql.init/` si se agrega | (completar) |
| Debug | Activo (WP_DEBUG / Drupal error level = verbose) | Desactivado |

## 4. Decisiones y ajustes detectados

(Registrar aquí cada ajuste no obvio hecho al construir el entorno, con su motivo —
igual que un changelog técnico. Ejemplo: por qué un volumen corre con HOST_UID en vez
de root, por qué una extensión PHP específica, etc.)

## 5. Deuda técnica y puntos abiertos

- (completar)
