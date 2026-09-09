# tech.md — Arquitectura técnica

**Proyecto:** {{PROJECT_NAME}} · **Stack:** {{STACK}} (imágenes Wodby) · **Última actualización:** {{DATE}}

## 1. Overview

{{OVERVIEW}}

## 2. Stack local

| Servicio | Imagen | Tag |
|---|---|---|
| mariadb | wodby/mariadb | ${MARIADB_TAG} |
| php | wodby/{{STACK}}-php | ${PHP_TAG} |
| nginx | wodby/nginx | ${NGINX_TAG} |
| adminer | wodby/adminer | ${ADMINER_TAG} |
| mailhog | mailhog/mailhog | (sin tag fijo — imagen de utilidad, no crítica) |

## 3. Diferencias con producción

| Aspecto | Local | Producción |
|---|---|---|
| Imágenes | Wodby (gestionadas) | (completar: hosting/imagen real) |
| Base de datos | MariaDB ${MARIADB_TAG} | (completar) |
| Dominio | localhost:${HTTP_PORT} | (completar) |
| Correo | Mailhog (atrapa todo, no envía) | (completar) |

## 4. Decisiones y ajustes detectados

(Registrar aquí cada ajuste no obvio hecho al construir el entorno, con su motivo.)

## 5. Deuda técnica y puntos abiertos

- (completar)
