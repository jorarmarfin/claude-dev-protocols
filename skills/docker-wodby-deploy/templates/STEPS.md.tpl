# Pasos de despliegue — {{PROJECT_NAME}} ({{STACK}})

## 1. Requisitos previos

- Docker y Docker Compose v2 instalados (`docker compose version`)
- Código fuente del proyecto ya presente en `./app` (docroot)
- Revisar y ajustar `.env` (passwords, puertos, tags de imagen)
- Carpeta del proyecto en el servidor: `{{DEPLOY_PATH}}` (varía según
  cliente/servidor — confirmar que coincide con este valor antes de
  desplegar, y usarlo en todos los pasos siguientes)

## 2. Primer levantamiento

**Dev/staging** (accesible desde cualquier IP que llegue al host en el
puerto — útil para probar desde otra máquina de la red):

```bash
docker compose up -d
docker compose ps
```

**Producción** (con virtualhost + certbot del paso 6/7 ya al frente —
el puerto del contenedor queda atado solo a `127.0.0.1`, nadie puede
saltarse el reverse proxy):

```bash
docker compose -f compose.yml -f compose.prod.yml up -d
docker compose ps
```

## 3. Post-arranque específico del stack

{{POST_STEPS}}

## 4. Verificar

- Sitio: http://localhost:{{HTTP_PORT}}
- Adminer (DB): http://localhost:{{ADMINER_PORT}}
- Mailhog (correo de pruebas): http://localhost:{{MAILHOG_PORT}}

```bash
docker compose logs -f php
```

## 5. Apagar / limpiar

```bash
docker compose down          # detiene contenedores, conserva volúmenes ({{DB_ENGINE}}/data)
docker compose down -v       # además borra los volúmenes con nombre (no {{DB_ENGINE}}/data, que es bind mount)
```

## 6. Virtualhost en el servidor ({{VHOST_SERVER}})

{{VHOST_STEPS}}

## 7. HTTPS con certbot (asume certbot ya instalado en el host)

Con el virtualhost del paso 6 ya habilitado y resolviendo el dominio
por HTTP, emitir el certificado:

```bash
{{CERTBOT_CMD}}
```

Verificar renovación automática (certbot ya instala el timer/cron):

```bash
sudo certbot renew --dry-run
```

## 8. Despliegue a servidor (CI/CD)

Ver `{{CI_FILE}}` — se dispara al hacer push a `main`. Configura los
secrets/variables de conexión SSH antes del primer deploy:
`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`, `DEPLOY_PATH`.

En este proyecto, `DEPLOY_PATH` = `{{DEPLOY_PATH}}`.

## Notas

- Los datos persistentes (`./{{DB_ENGINE}}/data`, `./moodledata` si
  aplica) quedan en la raíz del proyecto — respaldarlos junto con el
  código.
- Nunca commitees `.env` con passwords reales; usa `.env.example` como
  plantilla versionada y `.env` real solo local/servidor (agregar a
  `.gitignore`).
- Fija siempre tags de imagen exactos (`PHP_TAG`, `NGINX_TAG`, etc.) —
  nunca `latest`, para que el build sea reproducible.
- Si este entorno tiene auth_basic: **la clave en texto plano vive en
  `.env`** (`HTTP_BASIC_AUTH_USER`/`HTTP_BASIC_AUTH_PASSWORD`) —
  `deploy/nginx/.htpasswd` solo tiene el hash, no se puede leer la
  clave desde ahí. Para regenerarla:
  `htpasswd -bc deploy/nginx/.htpasswd "$HTTP_BASIC_AUTH_USER" "$HTTP_BASIC_AUTH_PASSWORD"`
  y luego actualiza `.env` con el mismo valor.
- Usa `compose.prod.yml` (`-f compose.yml -f compose.prod.yml`) recién
  cuando este proyecto quede detrás de un virtualhost real (paso 6/7)
  — antes de eso, déjalo con solo `compose.yml` para poder verlo desde
  cualquier IP mientras pruebas.
