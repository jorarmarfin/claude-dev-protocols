# {{PROJECT_NAME}} — entorno local (Wodby)

Fuente de verdad operativa del entorno Docker local (imágenes Wodby). Detalle de
puesta en marcha en [`STEPS.md`](./STEPS.md); comandos del día a día en
[`COMMANDS.md`](./COMMANDS.md).

## Requisitos

- Docker y Docker Compose
- (opcional) [mkcert](https://github.com/FiloSottile/mkcert), solo si defines
  `LOCAL_DOMAIN` en `.env` para TLS local

## Despliegue

```bash
./scripts/setup.sh
docker compose up -d
./scripts/bootstrap.sh
```

## Acceso

| Recurso | URL |
|---|---|
| Sitio | http://localhost:${HTTP_PORT} |
| Adminer (BD) | http://localhost:${ADMINER_PORT} |
| Mailhog (correo) | http://localhost:${MAILHOG_PORT} |

## Diferencias deliberadas con producción

Ver [`_specs/tech.md`](./_specs/tech.md) §3.

## Estructura

Ver [`_specs/estructura.md`](./_specs/estructura.md).

## Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---|---|---|
| `docker compose up` falla en `mariadb` con permisos | `${DB_DATA_PATH}` con dueño incorrecto de una corrida anterior | `docker compose down && rm -rf ${DB_DATA_PATH} && ./scripts/setup.sh` |
| 502 Bad Gateway en nginx | `php` no llegó a levantar | `docker compose logs php` |
| Correo no llega a Mailhog | La app no apunta a `mailhog:1025` como SMTP/sendmail | Revisar `PHP_SENDMAIL_PATH` en `compose.yml` (ya viene configurado por default) |
| Puerto ya en uso | Otro proyecto Docker usando el mismo `HTTP_PORT`/`ADMINER_PORT`/`MAILHOG_PORT` | Cambiar los puertos en `.env` |
