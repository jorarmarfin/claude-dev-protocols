# {{PROJECT_NAME}} — entorno local

Entorno Docker local para {{STACK}}, instalación limpia. Fuente de verdad operativa:
requisitos, comandos, diferencias con producción y troubleshooting.

## Requisitos

- Docker y Docker Compose
- [mkcert](https://github.com/FiloSottile/mkcert) (opcional — certificado TLS de
  confianza local; si no está, `setup.sh` genera uno autofirmado)

## Despliegue

```bash
./scripts/setup.sh
docker compose up -d
docker compose run --rm --entrypoint bash {{CLI_SERVICE}} /scripts/bootstrap.sh
```

## Acceso

| Recurso | URL |
|---|---|
| Sitio | https://{{PROJECT_NAME}}.localhost |
| Admin | {{ADMIN_URL}} |

Credenciales en `.env` (`{{ADMIN_USER_VAR}}` / `{{ADMIN_PASSWORD_VAR}}`).

## Comandos frecuentes

```bash
# Shell interactiva
docker compose exec php bash

# CLI del CMS
docker compose run --rm {{CLI_SERVICE}} {{CLI_EXAMPLE}}

# Logs
docker compose logs -f nginx
docker compose logs -f db

# Reset completo (borra BD y reinstala desde cero)
docker compose down
rm -rf mysql
docker compose up -d
docker compose run --rm --entrypoint bash {{CLI_SERVICE}} /scripts/bootstrap.sh
```

## Diferencias deliberadas con producción

Ver [`_specs/tech.md`](./_specs/tech.md) §3.

## Estructura

Ver [`_specs/estructura.md`](./_specs/estructura.md).

## Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `docker compose up` falla en `db` con permisos | `./mysql` con dueño incorrecto de una corrida anterior | `docker compose down && rm -rf mysql && ./scripts/setup.sh` |
| Certificado no confiado en el navegador | mkcert no instalado o CA no confiada | Instalar mkcert y correr `mkcert -install` antes de `setup.sh` |
| 502 Bad Gateway en nginx | `php` no llegó a levantar (build o extensión faltante) | `docker compose logs php` |
| Cambios en `docker/php/Dockerfile` no se aplican | Imagen cacheada | `docker compose build --no-cache php {{CLI_SERVICE}}` |

## Fases del proyecto

Ver [`_specs/prod.md`](./_specs/prod.md) §5.
