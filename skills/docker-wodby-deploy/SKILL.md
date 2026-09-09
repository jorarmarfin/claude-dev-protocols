---
name: docker-wodby-deploy
description: Genera compose.yml, .env, la estructura scripts/setup.sh+bootstrap.sh, _specs/ versionado (tech.md/estructura.md) y README.md operativo, virtualhost (nginx o apache) con comandos certbot, pipeline de CI/CD (GitHub Actions o Bitbucket Pipelines) y STEPS.md/COMMANDS.md para desplegar con Docker proyectos Drupal, Laravel, WordPress o Moodle usando las imágenes de Wodby, mapeando siempre los volúmenes en la raíz del proyecto. Usar cuando el usuario pida "desplegar con docker", "compose.yml para [drupal|laravel|wordpress|moodle]", "dockerizar este proyecto con wodby", "virtualhost + certbot para este despliegue", o quiera armar CI/CD para un despliegue Docker de estos stacks. Para WordPress/Drupal con infraestructura propia (sin Wodby) usa el skill wp-drupal-scaffold en su lugar.
---

# Skill: Docker Wodby Deploy

## Propósito

Generar en la carpeta actual (la raíz del proyecto que se va a
desplegar) todo lo necesario para levantarlo con Docker usando las
imágenes de [Wodby](https://wodby.com/stacks/): `compose.yml`, `.env`
(y `.env.example` versionable), la carpeta `scripts/` con `setup.sh`
(prepara `.env`, carpetas de datos y certificado TLS local) y
`bootstrap.sh` (post-provisioning idempotente vía CLI del stack: crear
admin, flush de permalinks/cachés, etc.), `_specs/` versionado
(`tech.md`, `estructura.md`), un `README.md` como fuente de verdad
operativa (con tabla de accesos y de troubleshooting), opcionalmente el
virtualhost del servidor (nginx o apache) con los comandos de certbot
para HTTPS, el pipeline de CI/CD del proveedor elegido, un `STEPS.md`
con los pasos concretos para levantar, verificar y desplegar, y un
`COMMANDS.md` con comandos del día a día (entrar al contenedor,
backup/restore de la DB, logs, reinicios).

Esta estructura de carpetas (`scripts/`, `_specs/`, `README.md`
operativo) es el mismo patrón de organización usado en el skill
hermano `wp-drupal-scaffold` (infraestructura propia, sin Wodby) — aquí
se aplica igual pero manteniendo las imágenes Wodby en `compose.yml`.

## Triggers

- "compose.yml para drupal/laravel/wordpress/moodle"
- "dockeriza este proyecto con wodby"
- "quiero desplegar con docker"
- "archivo de CI/CD para este despliegue" (en contexto de un proyecto
  de estos 4 stacks)

## Comportamiento

### 0. Preguntas previas (usar `AskUserQuestion`, no asumir)

En este orden, y sin generar nada hasta tener respuesta:

1. **¿Qué proyecto vas a desplegar?** Drupal / Laravel / WordPress / Moodle
2. **Nombre del proyecto** (necesario ya en este punto: es lo que llena
   `PROJECT_NAME` en el `.env` que se genera en el paso 1, nombra los
   contenedores, y evita colisión si el usuario tiene varios stacks
   Docker corriendo en la misma máquina — sin esto no se puede generar
   el `.env` correctamente).
3. **¿Ya tienes los archivos del proyecto en esta carpeta** (la carpeta
   donde se está ejecutando el skill)? Antes de preguntar, haz `ls -la`
   de la carpeta actual para tener contexto real y no preguntar a
   ciegas.
   - Si el usuario dice que sí pero `ls` muestra una carpeta vacía o sin
     nada reconocible del stack (sin `composer.json`/`wp-config.php`/
     `config.php` de Moodle/etc.), avisa la discrepancia y confirma cómo
     continuar antes de seguir.
   - Si dice que no, avisa que el `compose.yml` se genera igual (es
     infraestructura, no requiere el código fuente presente), pero que
     debe colocar el código en la raíz antes del primer `docker compose
     up` porque los volúmenes se mapean ahí.
4. **Motor de base de datos**: MariaDB (default, todos los templates lo
   usan) u otra variante si el usuario la pide explícitamente — si pide
   otra, ajusta el `compose.yml` a mano en vez de forzar el template.
5. **CI/CD**: GitHub Actions o Bitbucket Pipelines.
6. **¿Quieres que genere el archivo de virtualhost del servidor?** Sí/No.
   - Si es sí: **¿nginx o apache?** (el servidor web del host, fuera de
     Docker — hace de reverse proxy hacia el `nginx` del contenedor
     wodby, no reemplaza el nginx interno del stack). Pide también el
     **dominio** (p. ej. `midominio.com`) y el **puerto a enlazar**
     (a qué puerto del host apunta el `proxy_pass`/`ProxyPass` del
     vhost) — sin dominio no tiene sentido generar ni el vhost ni los
     comandos de certbot. Propón como default el `HTTP_PORT` que ya
     quedó fijado en el `.env` (paso 2), pero confirma explícitamente:
     si el usuario va a desplegar varios proyectos en el mismo host,
     cada dominio necesita apuntar a su propio puerto, así que no
     asumas que siempre coincide con el default.
   - Si es no, omite por completo el paso 4 de más abajo (no generes
     vhost ni comandos certbot, y quita esa sección del `STEPS.md`).
7. **¿En qué carpeta va a vivir el proyecto en el servidor?** (ruta
   absoluta, ej. `/var/www/html`, `/var/www/midominio.com`,
   `/var/www/data/midominio`) — varía según el cliente/servidor, no
   asumas `/var/www/html` por default. Este valor es el que va en
   `DEPLOY_PATH` del CI/CD (paso 4) y en las instrucciones de
   instalación del vhost (paso 3), así que pregúntalo siempre aunque el
   usuario no vaya a generar CI/CD ni vhost en este momento — sirve
   igual como referencia en `STEPS.md`.

No preguntes por cosas que ya se puedan inferir del directorio (p. ej.
si ya hay un `composer.json` con `laravel/framework`, no preguntes de
nuevo qué stack es — solo confírmalo).

### 1. Elegir y copiar el template correcto

Los templates viven en `templates/` de este skill:

```
templates/
  compose/
    drupal.compose.yml.tpl
    laravel.compose.yml.tpl
    wordpress.compose.yml.tpl
    moodle.compose.yml.tpl
  env/
    drupal.env.tpl
    laravel.env.tpl
    wordpress.env.tpl
    moodle.env.tpl
  ci/
    github-actions-deploy.yml.tpl
    bitbucket-pipelines.yml.tpl
  STEPS.md.tpl
  COMMANDS.md.tpl
```

Copia el `.tpl` del stack elegido a la raíz del proyecto destino:

- `templates/compose/<stack>.compose.yml.tpl` → `./compose.yml`
- `templates/env/<stack>.env.tpl` → `./.env` **y** `./.env.example`
  (mismo contenido, pero `.env.example` con los passwords reemplazados
  por placeholders tipo `CAMBIA_ESTA_PASSWORD` — nunca commitear
  passwords reales)

Todos los templates de compose mapean, dentro de la misma carpeta
principal que contiene el `compose.yml`:

- El código del proyecto: `${PROJECT_ROOT}:/var/www/html` (por
  default `./app`)
- Los datos de MariaDB: `${DB_DATA_PATH}:/var/lib/mysql` (por default
  `./mariadb/db-data`)
- Moodle además: `${MOODLEDATA_PATH}:/var/www/moodledata` (por default
  `./moodledata`)
- Backups de archivos y BD: `${BACKUPS_PATH}:/backups` (por default
  `./backups`), montado tanto en el contenedor de la app (`php`) como
  en el de la base de datos (`mariadb`)

Todo relativo al `compose.yml`, nunca en volúmenes con nombre sueltos
gestionados por Docker fuera del proyecto, para que un backup de la
carpeta principal se lleve todo (código, datos y respaldos).

### 2. Ajustar el `.env` con los valores reales

Reemplaza en el `.env` generado (no en `.env.example`):
- `PROJECT_NAME` con el nombre que dio el usuario
- Passwords de DB con valores fuertes generados (no dejes el
  placeholder en el `.env` real)
- Puertos si el usuario menciona que ya tiene algo corriendo en 8000/9000/8025

Verifica que `.env` esté en `.gitignore` del proyecto destino (créalo o
añade la línea si falta) — `.env.example` sí se versiona.

### 2.5 Estructura de carpetas: `scripts/`, `_specs/`, `README.md`

Los templates viven en `templates/scripts/`, `templates/specs/` y
`templates/README.md.tpl`:

```
templates/
  scripts/
    setup.sh.tpl
    bootstrap.wordpress.sh.tpl
    bootstrap.drupal.sh.tpl
    bootstrap.laravel.sh.tpl
    bootstrap.moodle.sh.tpl
  specs/
    tech.md.tpl
    estructura.md.tpl
  README.md.tpl
```

Copia y rellena placeholders (`{{PROJECT_NAME}}`, `{{STACK}}`, `{{DATE}}`):

- `templates/scripts/setup.sh.tpl` → `./scripts/setup.sh` (`chmod +x`)
- `templates/scripts/bootstrap.<stack>.sh.tpl` → `./scripts/bootstrap.sh`
  (`chmod +x`) — usa el del stack elegido en el paso 0.1, descarta los otros
- `templates/specs/tech.md.tpl` → `./_specs/tech.md`
- `templates/specs/estructura.md.tpl` → `./_specs/estructura.md`
- `templates/README.md.tpl` → `./README.md` (referencia a `STEPS.md` y
  `COMMANDS.md` del paso 5-6, no los reemplaza)

Si el usuario ya tiene overrides locales del stack (un `wp-config.local.php`,
un `settings.local.php` de Drupal, un `php.ini` extra), colócalos en
`docker/<servicio>/` y móntalos como volumen adicional en el servicio
correspondiente del `compose.yml` — las imágenes Wodby no necesitan
Dockerfile propio, así que `docker/` aquí es solo para estos overrides
puntuales, no para reconstruir la imagen.

### 3. Virtualhost del servidor + certbot (solo si el usuario lo pidió en 0.6)

Los templates viven en `templates/vhost/`:

```
templates/vhost/
  nginx.conf.tpl
  apache.conf.tpl
```

- Copia el `.tpl` correspondiente reemplazando `{{DOMAIN}}` (dominio
  dado en 0.6) y `{{HTTP_PORT}}` con el puerto confirmado en 0.6 (por
  default el mismo `HTTP_PORT` del `.env`, pero puede ser otro si el
  usuario está enlazando este dominio a un puerto distinto) al archivo
  destino:
  - nginx → `./deploy/nginx/{{DOMAIN}}.conf` (el usuario lo copia a
    `/etc/nginx/sites-available/` en el servidor real y enlaza en
    `sites-enabled`)
  - apache → `./deploy/apache/{{DOMAIN}}.conf` (a
    `/etc/apache2/sites-available/`)
- Ambos templates son reverse proxy hacia `127.0.0.1:{{HTTP_PORT}}`
  (el puerto que `compose.yml` expone del contenedor `nginx` de
  wodby) — el servidor web del host no sirve el docroot directamente.
- No los coloques en `/etc/nginx` o `/etc/apache2` directamente — este
  skill solo genera el archivo en el proyecto (`./deploy/...`); copiarlo
  al sistema y recargar el servicio es un paso manual del usuario en el
  servidor (indícalo en `STEPS.md`, no lo ejecutes tú salvo que el
  usuario esté en ese mismo servidor y lo pida explícitamente).

**Comandos de certbot** (asume que certbot ya está instalado — este
skill no lo instala): añade a `STEPS.md` el comando según el servidor
elegido:

```bash
# nginx (plugin nginx, ajusta el vhost automáticamente y recarga)
sudo certbot --nginx -d {{DOMAIN}} -d www.{{DOMAIN}}

# apache (plugin apache, ajusta el vhost automáticamente y recarga)
sudo certbot --apache -d {{DOMAIN}} -d www.{{DOMAIN}}
```

Y siempre el comando de verificación de renovación automática:

```bash
sudo certbot renew --dry-run
```

### 4. Generar el archivo de CI/CD

Según lo elegido en el paso 0.4:

- **GitHub Actions**: copia `templates/ci/github-actions-deploy.yml.tpl`
  a `.github/workflows/deploy.yml` (crea la carpeta si no existe)
- **Bitbucket Pipelines**: copia
  `templates/ci/bitbucket-pipelines.yml.tpl` a `bitbucket-pipelines.yml`
  en la raíz

Ajusta el bloque de "post-deploy específico del stack" (migraciones/
`drush updb`/`wp core update-db`/`admin/cli/upgrade.php`) dejando
activo solo el comando del stack elegido, comentando los otros o
eliminándolos.

Avisa al usuario qué secrets/variables debe configurar en el
repositorio (`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`,
`DEPLOY_PATH`) — este skill no los configura, solo genera el pipeline.
Dile explícitamente el valor que debe poner en `DEPLOY_PATH` (la ruta
del paso 0.7), para que no quede como incógnita al momento de crear el
secret/variable en GitHub/Bitbucket.

### 5. Generar `STEPS.md`

Copia `templates/STEPS.md.tpl` a `./STEPS.md` en la raíz, rellenando:
- `{{PROJECT_NAME}}`, `{{STACK}}`
- `{{HTTP_PORT}}`, `{{ADMINER_PORT}}`, `{{MAILHOG_PORT}}` con los
  valores reales del `.env`
- `{{POST_STEPS}}` con los comandos específicos del stack elegido
  (instalación inicial de Drupal/WordPress/Moodle, o
  `artisan migrate`/`artisan key:generate` en Laravel)
- `{{CI_FILE}}` con la ruta del archivo de CI/CD generado en el paso 4
- `{{DEPLOY_PATH}}` con la ruta dada en 0.7 (carpeta del proyecto en el
  servidor) — úsala también dentro de los comandos de instalación del
  vhost (`cp .../{{DOMAIN}}.conf /etc/nginx/sites-available/...`) para
  que quede claro dónde vive todo, ya que varía según cliente/servidor
- Si el usuario pidió virtualhost (0.6): `{{VHOST_SERVER}}` (nginx o
  apache) y `{{VHOST_STEPS}}` con la ruta del archivo generado en el
  paso 3, cómo instalarlo en el servidor (`sites-available` +
  `sites-enabled`/`a2ensite` + reload) y el comando `{{CERTBOT_CMD}}`
  correspondiente
- Si el usuario **no** pidió virtualhost, elimina del `STEPS.md`
  generado las secciones 6 y 7 del template (virtualhost y certbot) —
  no las dejes con placeholders sin rellenar

### 6. Generar `COMMANDS.md`

Copia `templates/COMMANDS.md.tpl` a `./COMMANDS.md` en la raíz,
rellenando `{{PROJECT_NAME}}`, `{{STACK}}`, `{{DB_USER}}`,
`{{DB_PASSWORD}}`, `{{DB_NAME}}` con los valores reales del `.env`, y
`{{STACK_COMMANDS}}` con comandos propios del stack elegido, por ejemplo:

- Drupal: `docker compose exec php drush cr`, `drush sql-dump`, `drush updb`
- Laravel: `docker compose exec php php artisan tinker`, `artisan queue:restart`, `artisan cache:clear`
- WordPress: `docker compose exec php wp cache flush`, `wp db export`
- Moodle: `docker compose exec php php admin/cli/purge_caches.php`

Este archivo es para el día a día (entrar al contenedor, backup/restore
de la DB, ver logs) — no lo confundas con `STEPS.md`, que es la guía de
puesta en marcha inicial y despliegue.

### 7. Resumen final

Termina siempre listando qué archivos se crearon o modificaron
(`compose.yml`, `.env`, `.env.example`, `scripts/setup.sh`,
`scripts/bootstrap.sh`, `_specs/tech.md`, `_specs/estructura.md`,
`README.md`, el archivo de CI/CD, `STEPS.md`, `COMMANDS.md`, cambios en
`.gitignore`) y el próximo comando a correr (`./scripts/setup.sh &&
docker compose up -d && ./scripts/bootstrap.sh`).

## Instrucciones especiales

- **Nunca uses `latest` como tag de imagen** en los templates — todos
  fijan una versión concreta; si el usuario no especifica, deja la que
  trae el `.tpl` y avísale que puede no ser la más reciente (sugiere
  verificar en https://hub.docker.com/u/wodby).
- **Volúmenes siempre dentro de la carpeta principal del proyecto**
  (`${PROJECT_ROOT}`, `${DB_DATA_PATH}`, `${MOODLEDATA_PATH}` en
  Moodle, `${BACKUPS_PATH}`), nunca volúmenes con nombre gestionados
  por Docker fuera del proyecto — es el requisito explícito del
  usuario, para que todo (código, datos y backups) viva en una sola
  carpeta portable junto al `compose.yml`.
- **`${BACKUPS_PATH}` (`./backups` por default) se monta como
  `/backups`** en el contenedor de la app y en el de la base de datos
  — es donde van los dumps de BD y los backups de archivos; menciónalo
  en `COMMANDS.md` al documentar los comandos de backup/restore.
- **Moodle no tiene imagen oficial de wodby tan estable** como
  drupal-php/wordpress-php — el template usa `wodby/php` genérico y
  deja una nota; verifica con el usuario si prefiere una imagen
  alternativa antes de dar el despliegue por cerrado.
- **No sobrescribas un `compose.yml` o `.env` ya existente sin avisar**
  — si ya existen en la carpeta destino, muéstraselos al usuario y
  confirma antes de reemplazar.
- **No inventes credenciales de servidor real** para el CI/CD — deja
  siempre placeholders de secrets/variables, nunca valores hardcodeados.
