# Comandos útiles — {{PROJECT_NAME}} ({{STACK}})

Todos asumen que se ejecutan desde la raíz del proyecto (donde está
`compose.yml`).

## Entrar a los contenedores

```bash
docker compose exec php sh          # shell dentro del contenedor PHP
docker compose exec mariadb sh      # shell dentro del contenedor de la DB
```

## Backup de la base de datos

```bash
mkdir -p backups
docker compose exec -T mariadb mysqldump -u{{DB_USER}} -p{{DB_PASSWORD}} {{DB_NAME}} | gzip > backups/{{PROJECT_NAME}}_$(date +%Y%m%d_%H%M%S).sql.gz
```

## Restaurar un backup

```bash
gunzip -c backups/{{PROJECT_NAME}}_YYYYMMDD_HHMMSS.sql.gz | docker compose exec -T mariadb mysql -u{{DB_USER}} -p{{DB_PASSWORD}} {{DB_NAME}}
```

## Backup de archivos (código + uploads, sin `.git` ni `node_modules`)

```bash
mkdir -p backups
tar --exclude='./{{DB_ENGINE}}' --exclude='./.git' --exclude='./node_modules' -czf backups/{{PROJECT_NAME}}_files_$(date +%Y%m%d_%H%M%S).tar.gz .
```

## Logs

```bash
docker compose logs -f php
docker compose logs -f nginx
docker compose logs -f mariadb
```

## Estado y reinicio de contenedores

```bash
docker compose ps
docker compose restart php
docker compose restart nginx
```

## Actualizar imágenes y recrear contenedores

```bash
docker compose pull
docker compose up -d --remove-orphans
```

## Ver puertos libres/ocupados del servidor (antes de fijar HTTP_PORT/ADMINER_PORT/etc. en .env)

```bash
sudo ss -tulpn | grep LISTEN
```

{{STACK_COMMANDS}}

## Notas

- Las passwords de arriba salen del `.env` de este proyecto — si las
  cambias ahí, actualiza también estos comandos (o mejor, usa
  `docker compose exec -T mariadb sh -c 'mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'`
  para no hardcodear nada).
- Programa el backup de DB (y de archivos) como cron en el servidor —
  este archivo solo documenta el comando, no lo agenda.
- Los backups quedan en `./backups/` dentro del proyecto — agrégalo a
  `.gitignore` si no quieres versionarlos.
