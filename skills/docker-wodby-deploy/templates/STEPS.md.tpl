# Pasos de despliegue — {{PROJECT_NAME}} ({{STACK}})

## 1. Requisitos previos

- Docker y Docker Compose v2 instalados (`docker compose version`)
- Código fuente del proyecto ya presente en esta carpeta (docroot en la raíz)
- Revisar y ajustar `.env` (passwords, puertos, tags de imagen)
- Carpeta del proyecto en el servidor: `{{DEPLOY_PATH}}` (varía según
  cliente/servidor — confirmar que coincide con este valor antes de
  desplegar, y usarlo en todos los pasos siguientes)

## 2. Primer levantamiento

```bash
docker compose up -d
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
docker compose down          # detiene contenedores, conserva volúmenes (./data)
docker compose down -v       # además borra los volúmenes con nombre (no ./data, que es bind mount)
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

- Los volúmenes de datos (`./data/mariadb`, `./data/moodledata` si aplica)
  quedan en la raíz del proyecto — respaldarlos junto con el código.
- Nunca commitees `.env` con passwords reales; usa `.env.example` como
  plantilla versionada y `.env` real solo local/servidor (agregar a
  `.gitignore`).
- Fija siempre tags de imagen exactos (`PHP_TAG`, `NGINX_TAG`, etc.) —
  nunca `latest`, para que el build sea reproducible.
