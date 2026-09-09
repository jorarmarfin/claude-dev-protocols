---
name: wp-drupal-scaffold
description: Genera un entorno Docker local para WordPress o Drupal con infraestructura propia (Dockerfile PHP a medida, MariaDB, nginx, wp-cli/drush), instalación limpia (sin dump de producción), siguiendo el patrón de organización de carpetas estándar del usuario — docker/{php,nginx,cms}/, scripts/setup.sh + bootstrap.sh, _specs/ versionado (tech.md/prod.md/estructura.md) y README.md operativo con tabla de troubleshooting. Usar cuando el usuario pida "scaffold de WordPress/Drupal", "entorno local nuevo para WordPress/Drupal", "arma un WordPress limpio con Docker", o mencione replicar la estructura del proyecto antamina_2026 para un sitio nuevo. NO usar para Laravel (usa laravel-composer-kit + project-scaffold) ni cuando el usuario pida explícitamente imágenes Wodby (usa docker-wodby-deploy) ni para migrar un dump de producción real a local (ese es un caso ad-hoc, adapta sql.init/ y docker/wordpress/wp-config.local.php a mano).
---

# Skill: WP/Drupal Scaffold (infraestructura propia, instalación limpia)

## Propósito

Generar en la carpeta actual (raíz del proyecto) un entorno Docker local completo
para **WordPress** o **Drupal**, con infraestructura propia (no imágenes Wodby):
Dockerfile de PHP a medida, MariaDB, nginx, y wp-cli/drush como servicio CLI —
apuntando a una **instalación limpia** (Drupal `site:install` / WordPress
`core install`), no a un dump de producción.

Esto replica el patrón de organización que le gustó al usuario en el proyecto
`antamina_2026` (una réplica local de un WordPress de producción), pero
generalizado para arrancar un sitio nuevo desde cero. Lo específico de ese
proyecto (hardening de WP Engine, dump real, tests a medida) **no** se replica
aquí — solo el patrón de organización.

## Triggers

- "scaffold de WordPress/Drupal con Docker"
- "entorno local nuevo para WordPress/Drupal"
- "arma un WordPress/Drupal limpio con Docker, con mi estructura estándar"
- "replica la estructura de antamina_2026 para un proyecto nuevo"

## Comportamiento

### 0. Preguntas previas (usar `AskUserQuestion`, no asumir)

1. **¿WordPress o Drupal?**
2. **Nombre del proyecto** (llena `PROJECT_NAME`, nombra contenedores y red).
3. **¿Ya tienes código del CMS en esta carpeta?** Haz `ls -la` primero para
   tener contexto real. Si no hay nada, avisa que el scaffold genera igual
   toda la infraestructura; el código (WordPress core, o `composer create-project
   drupal/recommended-project` para Drupal) se instala después con
   `docker compose run --rm {{cli}} composer install` o dejando que
   `bootstrap.sh` corra la instalación limpia sobre un contenedor vacío
   (para WordPress, `wp core download` dentro del contenedor si `wordpress/`
   está vacío).
4. **Versión de PHP** (default `8.3`) y **versión de MariaDB** (default `11.4`).
5. **Dominio local** (default `{{PROJECT_NAME}}.localhost` — el TLD
   `.localhost` resuelve a 127.0.0.1 sin tocar `/etc/hosts`).
6. **¿Vas a importar un dump existente o es instalación limpia?**
   - Limpia (default): `bootstrap.sh` corre `wp core install` / `drush
     site:install`.
   - Dump existente: pide la ruta del `.sql`/`.sql.gz`, indícale que lo copie
     a `./sql.init/`, y anota en `_specs/tech.md` que esto es una réplica de
     producción, no una instalación limpia (esto empieza a parecerse al caso
     antamina — si el usuario confirma que es exactamente ese caso, avisa que
     también puede necesitar neutralizar mu-plugins/hardening de plataforma a
     mano, fuera de este skill).
7. **¿Vas a generar la carpeta `tests/` con el esqueleto de Playwright?**
   Sí/No — es opcional, no todos los proyectos lo necesitan desde el día 1.

### 1. Crear la estructura de carpetas y copiar templates

Los templates viven en `templates/` de este skill:

```
templates/
  compose/{wordpress,drupal}.compose.yml.tpl
  env/{wordpress,drupal}.env.tpl
  docker/php/Dockerfile.{wordpress,drupal}.tpl
  docker/php/php.ini.tpl
  docker/nginx/default.conf.{wordpress,drupal}.tpl
  docker/nginx/security-headers.conf.tpl
  docker/wordpress/wp-config.local.php.tpl
  docker/drupal/settings.local.php.tpl
  scripts/setup.sh.tpl
  scripts/bootstrap.{wordpress,drupal}.sh.tpl
  specs/{tech,prod,estructura}.md.tpl
  README.md.tpl
  gitignore.tpl
  tests/README.md.tpl
```

Copia y renombra reemplazando `{{PROJECT_NAME}}`, `{{STACK}}`, `{{DATE}}`
(fecha actual), `{{PHP_VERSION}}`, `{{DOCROOT}}` (`wordpress` o `drupal`),
`{{CLI_SERVICE}}` (`wpcli` o `drush`) y demás placeholders por los valores
reales del paso 0:

- `templates/compose/<stack>.compose.yml.tpl` → `./docker-compose.yml`
- `templates/env/<stack>.env.tpl` → `./.env.example` **y** `./.env` (en el
  `.env` real, reemplaza los `CAMBIA_ESTA_PASSWORD` por passwords generados,
  nunca los dejes ahí)
- `templates/docker/php/Dockerfile.<stack>.tpl` → `./docker/php/Dockerfile`
- `templates/docker/php/php.ini.tpl` → `./docker/php/php.ini`
- `templates/docker/nginx/default.conf.<stack>.tpl` →
  `./docker/nginx/default.conf.template`
- `templates/docker/nginx/security-headers.conf.tpl` →
  `./docker/nginx/security-headers.conf`
- WordPress: `templates/docker/wordpress/wp-config.local.php.tpl` →
  `./docker/wordpress/wp-config.local.php`
- Drupal: `templates/docker/drupal/settings.local.php.tpl` →
  `./docker/drupal/settings.local.php`
- `templates/scripts/setup.sh.tpl` → `./scripts/setup.sh` (`chmod +x`)
- `templates/scripts/bootstrap.<stack>.sh.tpl` → `./scripts/bootstrap.sh`
  (`chmod +x`)
- `templates/specs/*.md.tpl` → `./_specs/*.md`
- `templates/README.md.tpl` → `./README.md`
- `templates/gitignore.tpl` → añade su contenido a `./.gitignore` (créalo si
  no existe; no sobrescribas un `.gitignore` existente, agrega las líneas que
  falten)
- Si el usuario pidió `tests/` en el paso 0.7:
  `templates/tests/README.md.tpl` → `./tests/README.md`, y crea
  `./tests/specs/` vacío como punto de partida (no generes casos de prueba
  específicos del sitio — eso depende del contenido real, es trabajo del
  usuario o de una sesión posterior)

Todos los volúmenes de datos (`./mysql`, `./certs`, `./sql.init` si aplica)
quedan **dentro de la carpeta principal del proyecto**, nunca en volúmenes con
nombre gestionados por Docker fuera del proyecto — mismo requisito que
`docker-wodby-deploy`, para que todo (código, infra, datos) sea portable en
una sola carpeta.

### 2. Ajustar `.env` con valores reales

Igual que en `docker-wodby-deploy`: reemplaza `PROJECT_NAME`, genera passwords
fuertes para `.env` (no para `.env.example`), y ajusta puertos si el usuario
menciona colisión con otros proyectos corriendo en la máquina.

### 3. Levantar y correr el bootstrap

Indica al usuario la secuencia:

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
docker compose up -d --build
docker compose run --rm --entrypoint bash {{CLI_SERVICE}} /scripts/bootstrap.sh
```

Si el paso 0.3 reveló que no hay código del CMS aún:
- WordPress: antes del bootstrap, `docker compose run --rm wpcli wp core
  download --force` (el volumen `./wordpress` debe existir y estar vacío).
- Drupal: `docker compose run --rm drush composer create-project
  drupal/recommended-project /var/www/html-tmp && mv ...` — o más simple,
  pide al usuario correr `composer create-project drupal/recommended-project
  drupal` en el host antes de levantar contenedores (más rápido y no requiere
  ajustar el volumen a mitad de instalación).

### 4. Resumen final

Lista los archivos creados (`docker-compose.yml`, `.env`, `.env.example`,
`docker/`, `scripts/setup.sh`, `scripts/bootstrap.sh`, `_specs/*.md`,
`README.md`, cambios en `.gitignore`, y `tests/` si se pidió) y el próximo
comando a correr.

## Instrucciones especiales

- **Nunca imágenes `latest`** — todas fijan versión concreta (PHP, MariaDB,
  nginx); si el usuario no especifica, usa el default del `.tpl`.
- **Volúmenes siempre dentro de la carpeta principal del proyecto** — mismo
  requisito que `docker-wodby-deploy`.
- **Instalación limpia por default.** Si el usuario en el paso 0.6 pide
  importar un dump real de producción con hardening de plataforma
  específico (WP Engine, Pantheon, Acquia, etc.), este skill genera la base
  pero **no** replica ese hardening — es trabajo manual del usuario sobre
  `docker/wordpress/` o `docker/drupal/` (mu-plugins vacíos, drop-ins dummy,
  etc., como en antamina_2026), avísaselo explícitamente.
- **No sobrescribas `docker-compose.yml`, `.env` o `_specs/*.md` existentes
  sin avisar** — muéstraselos al usuario y confirma antes de reemplazar.
- **No inventes credenciales de servidor real** para nada relacionado a
  despliegue a producción — este skill es solo para el entorno local.
- **`tests/` es opcional y deliberadamente mínimo** — solo genera el README
  con la convención de nomenclatura de reportes
  (`fecha_hora__contexto__modo__veredicto`); los specs de prueba reales
  dependen del contenido del sitio y no se generan aquí.
