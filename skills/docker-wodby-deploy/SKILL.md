---
name: docker-wodby-deploy
description: Genera compose.yml, .env, virtualhost (nginx o apache) con comandos certbot, pipeline de CI/CD (GitHub Actions o Bitbucket Pipelines) y un archivo de pasos para desplegar con Docker proyectos Drupal, Laravel, WordPress, Moodle o Joomla usando las imágenes de Wodby, mapeando siempre el código en ./app, los datos de cada motor de DB en ./<motor>/data, y toda la config de Docker (vhost, extra.conf, .htpasswd) en ./deploy. Usar cuando el usuario pida "desplegar con docker", "compose.yml para [drupal|laravel|wordpress|moodle|joomla]", "dockerizar este proyecto con wodby", "virtualhost + certbot para este despliegue", o quiera armar CI/CD para un despliegue Docker de estos stacks.
---

# Skill: Docker Wodby Deploy

## Propósito

Generar en la carpeta actual (la raíz del proyecto que se va a
desplegar) todo lo necesario para levantarlo con Docker usando las
imágenes de [Wodby](https://wodby.com/stacks/): `compose.yml`, `.env`
(y `.env.example` versionable), opcionalmente el virtualhost del
servidor (nginx o apache) con los comandos de certbot para HTTPS, el
pipeline de CI/CD del proveedor elegido, un `STEPS.md` con los pasos
concretos para levantar, verificar y desplegar, y un `COMMANDS.md` con
comandos del día a día (entrar al contenedor, backup/restore de la DB,
logs, reinicios).

## Triggers

- "compose.yml para drupal/laravel/wordpress/moodle/joomla"
- "dockeriza este proyecto con wodby"
- "quiero desplegar con docker"
- "archivo de CI/CD para este despliegue" (en contexto de un proyecto
  de estos stacks)
- "prepara/acomoda/adapta este proyecto a nuestro estándar (de
  despliegue)" — dispara el modo migración/limpieza, no solo
  generación (ver nota en el paso 1)

## Comportamiento

### 0. Preguntas previas (usar `AskUserQuestion`, no asumir)

En este orden, y sin generar nada hasta tener respuesta:

1. **¿Qué proyecto vas a desplegar?** Drupal / Laravel / WordPress / Moodle / Joomla
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
   - Y también **¿qué distro corre el servidor?** Familia Debian
     (Ubuntu/Debian) o familia RedHat (RHEL/Rocky/AlmaLinux/CentOS) — las
     rutas, el nombre del servicio/paquete y los comandos de habilitación
     difieren entre ambas (ver paso 3), así que no asumas Debian/Ubuntu
     por default; pregunta explícitamente. Si el usuario no sabe, sugiere
     correr `cat /etc/os-release` en el servidor para confirmar antes de
     generar el vhost.
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
8. **¿Vas a usar Adminer?** Sí/No — todos los templates de compose
   incluyen el servicio `adminer` por default, pero en producción
   suele ser mejor no exponerlo.
   - Si es no: quita el servicio `adminer` completo del `compose.yml`
     copiado (bloque `adminer:` y sus `depends_on` de otros servicios
     si alguno lo tuviera) y quita `ADMINER_PORT`/`ADMINER_TAG` del
     `.env`/`.env.example` generados. No dejes el servicio comentado
     ni variables sueltas sin uso.
   - Si es sí (default más común en staging/desarrollo): déjalo tal
     cual trae el template.

**El stack por default es siempre nginx + php + mariadb (+ adminer si
el usuario no dijo que no en 0.8) — nunca agregues un contenedor de
correo (mailhog/mailpit/etc.) ni `PHP_SENDMAIL_PATH` apuntando a uno**,
ninguno de los templates de compose lo trae. Solo agrégalo si el
usuario lo pide explícitamente para este despliegue puntual.
9. **¿El entorno va a tener usuario/clave (auth_basic) o queda
   abierto?** Sí/No — típico en staging/interno para bloquear acceso
   público mientras no hay dominio ni HTTPS todavía.
   - Si es sí: no le pidas al usuario que invente la clave — genérala
     tú (ej. `openssl rand -base64 18 | tr -d '/+=' | cut -c1-16`) y
     pídele solo el usuario (o usa el `PROJECT_NAME` si no especifica).
     Guarda **usuario y clave en texto plano en `.env`** como
     `HTTP_BASIC_AUTH_USER`/`HTTP_BASIC_AUTH_PASSWORD` — es la única
     fuente donde se puede leer la clave después, porque el archivo
     `.htpasswd` que realmente usa nginx solo guarda un hash
     irreversible. Genera `.htpasswd` con
     `htpasswd -bc deploy/nginx/.htpasswd "$HTTP_BASIC_AUTH_USER" "$HTTP_BASIC_AUTH_PASSWORD"`
     (o `openssl passwd -apr1` si `htpasswd` no está instalado, armando
     la línea `usuario:hash` a mano). Documenta en `STEPS.md` que la
     clave vive en `.env` y el comando exacto para regenerarla si
     cambia. Nunca generes un `.htpasswd` sin dejar la clave en texto
     plano en algún lugar que el usuario pueda encontrar — es
     exactamente el error a evitar (una clave que ni el propio usuario
     puede recuperar después).
   - Si es no: no generes `.htpasswd` ni el bloque `auth_basic` en
     `extra.conf`.

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
    joomla.compose.yml.tpl
    compose.prod.yml.tpl
  env/
    drupal.env.tpl
    laravel.env.tpl
    wordpress.env.tpl
    moodle.env.tpl
    joomla.env.tpl
  ci/
    github-actions-deploy.yml.tpl
    bitbucket-pipelines.yml.tpl
  STEPS.md.tpl
  COMMANDS.md.tpl
```

Copia el `.tpl` del stack elegido a la raíz del proyecto destino:

- `templates/compose/<stack>.compose.yml.tpl` → `./compose.yml`
- `templates/compose/compose.prod.yml.tpl` → `./compose.prod.yml`
  (siempre, no solo si el usuario pidió virtualhost en 0.6 — lo usa el
  día que promueva este mismo proyecto a producción, así ya lo tiene
  listo)
- `templates/env/<stack>.env.tpl` → `./.env` **y** `./.env.example`
  (mismo contenido, pero `.env.example` con los passwords reemplazados
  por placeholders tipo `CAMBIA_ESTA_PASSWORD` — nunca commitear
  passwords reales)

**Dev/staging vs producción — quién puede ver el sitio por el puerto
publicado:** `compose.yml` solo (`docker compose up -d`) publica los
puertos del `nginx`/`adminer` en todas las interfaces (`0.0.0.0`), así
que el sitio es alcanzable desde cualquier IP que llegue al host en
ese puerto — es lo que se quiere en dev/staging, para poder abrirlo
desde otra máquina de la red sin necesitar un dominio. Al agregar el
override (`docker compose -f compose.yml -f compose.prod.yml up -d`),
esos mismos puertos quedan atados a `127.0.0.1` — solo el propio
servidor puede alcanzarlos, porque en producción el tráfico entra por
el virtualhost del host (nginx/apache + certbot, ver paso 3) y el
puerto del contenedor no debe quedar abierto a cualquiera. Explícale
esto al usuario en el resumen final y en `STEPS.md` — es fácil asumir
que "producción" implica agregar el override, y si el usuario nunca lo
corre, seguirá expuesto en todas las interfaces sin darse cuenta.

**El contenedor `wodby/nginx` escucha internamente en el puerto `80`,
no en `8080`** — a pesar de que otras imágenes wodby (y ejemplos
antiguos) usan 8080 en algunos stacks. Todos los templates ya mapean
`"${HTTP_PORT}:80"` (y `compose.prod.yml` `"127.0.0.1:${HTTP_PORT}:80"`
en su override) — nunca cambies esto a `:8080` sin verificar primero
con `docker compose exec nginx sh -c "ss -tlnp"` dentro del contenedor
real, porque un mapeo al puerto equivocado da `ERR_CONNECTION_RESET`
(el puerto del host abre pero nadie escucha del otro lado) en vez de
un error obvio de Docker.

**Verificar el docroot real antes de dar el compose por bueno**: si el
proyecto usa `drupal/recommended-project` (composer, lo más común desde
Drupal 8+), el código fuente vive en `app/web/` dentro del bind mount
`./app:/var/www/html`, así que el `root` de nginx debe ser
`/var/www/html/web`, no `/var/www/html` — el template de Drupal ya trae
`NGINX_SERVER_ROOT: /var/www/html/web` por esto. Antes de dar el
despliegue por cerrado, confirma con `ls app/web/index.php` (o
equivalente `public/index.php` en Laravel, WordPress con estructura
Bedrock, etc.) qué subcarpeta es el docroot real, y ajusta
`NGINX_SERVER_ROOT` si no coincide con lo que trae el template — un
`root` mal apuntado da `404 Not Found` en vez de un error claro.

**Verificar la versión de PHP que exige el proyecto, no solo la que
"suena razonable" para el framework**: revisa
`app/vendor/composer/platform_check.php` (si ya existe `vendor/`) o el
`require.php` de `composer.json`/`composer.lock` — si el proyecto ya
tiene `vendor/` instalado con una versión de PHP más nueva que la que
trae el `.env` por default, el `platform_check.php` de Composer lanza
un 500 (`Composer detected issues in your platform`) en vez de un error
más claro. Ajusta `PHP_TAG` a una versión que cumpla el mínimo exigido
(verifica que el tag exista con `docker manifest inspect
wodby/<imagen-php>:<tag>` antes de fijarlo, como con cualquier otro tag).

Todos los templates de compose mapean el código del proyecto con un
bind mount a `./app:/var/www/html` (el docroot vive en la subcarpeta
`app/`, nunca en la raíz — así `compose.yml`, `deploy/`, dumps SQL y
backups quedan fuera del webroot) y los datos persistentes de cada
motor en una carpeta de nivel raíz **con el nombre del motor**, y
dentro una subcarpeta `data/`: `./mariadb/data`, `./mysql/data`,
`./postgres/data` — el nombre depende del motor real que use el
proyecto, no siempre "mariadb". Nunca `./data/<motor>` (el motor va
primero, no la palabra genérica). Esto siempre dentro de la raíz del
proyecto, nunca en volúmenes con nombre sueltos, para que un backup de
carpeta se lleve todo. Datos de aplicación que no son de un motor de
DB (ej. `moodledata`) van en su propia carpeta de nivel raíz con su
propio nombre (`./moodledata`), sin el patrón `<nombre>/data`.

**Siempre mapear también `./<motor>/init:/docker-entrypoint-initdb.d`**
en el servicio de base de datos, para cualquier motor (MariaDB, MySQL,
Postgres) — todas las imágenes de bases de datos que usan estos
templates soportan esa convención: cualquier `.sql`/`.sh`/`.sql.gz` que
haya dentro se ejecuta automáticamente la primera vez que el
contenedor arranca con el volumen de datos (`./<motor>/data`) vacío.
Es el lugar estándar para dejar un dump inicial (ej. un
`drupal_11.sql`) en vez de deambulando en la raíz del proyecto o
importado a mano — si el usuario ya tiene un dump `.sql` en la carpeta
del proyecto al generar el compose, muévelo a `./<motor>/init/` y
documenta en `STEPS.md`/`COMMANDS.md` que el import es automático solo
en el primer arranque (si `./<motor>/data` ya tiene datos, el dump no
se reimporta solo — hay que correrlo a mano contra el contenedor).
Aplica este mapeo aunque el usuario no haya pedido explícitamente un
import inicial: es parte del estándar del compose, no una opción.

**Si el usuario pide "prepara/acomoda/adapta este proyecto a nuestro
estándar"** (no solo "genera el compose.yml"), esto es una migración de
un proyecto existente al estándar, no una adición: identifica cada
desviación y córrigela moviendo/renombrando/borrando lo viejo, dejando
un solo estado final limpio — nunca los dos (el viejo y el nuevo)
convivientes. Revisa al menos:

- **Docroot**: si el código fuente está en la raíz, en `public_html/`,
  `htdocs/`, `web/`, etc. en vez de `app/` → `mv` a `app/` (no copiar
  dejando el original), y actualiza toda referencia a la ruta vieja en
  `compose.yml`, `.gitignore`, `STEPS.md`, `COMMANDS.md` y cualquier
  config del propio stack que apunte a rutas absolutas del contenedor
  (esas casi siempre no cambian porque ya son `/var/www/html`, pero
  revisa igual).
- **Config del stack con la carpeta vieja hardcodeada**: si algún
  archivo de config (settings.php, wp-config.php, configuration.php,
  config.php, .env de la app) referencia rutas o nombres que asumían la
  carpeta vieja, actualízalo.
- **Carpeta de infraestructura Docker**: todo lo relacionado a Docker
  (vhost, extra.conf, .htpasswd, etc.) vive en `./deploy/` — si existe
  una carpeta `docker/` u otro nombre suelto con el mismo propósito,
  mueve su contenido a `./deploy/` y borra la carpeta vieja.
- **Volúmenes de datos**: si `compose.yml` usa un volumen con nombre de
  Docker (bloque `volumes:` al final del archivo), o un bind mount en
  `./data/<motor>` (patrón viejo), migra al bind mount visible
  `./<motor>/data/` (ej. `./mariadb/data`) y borra la declaración vieja
  — si ya tiene datos y el contenedor no está corriendo, puedes
  copiarlos sin sudo con un contenedor que corra como root sobre el
  bind mount (evita problemas de ownership del host):
  `docker run --rm -v $(pwd):/proj alpine sh -c 'mv /proj/data/<motor>/* /proj/<motor>/data/ && rmdir /proj/data/<motor> /proj/data && chown -R $(id -u):$(id -g) /proj/<motor>/data'`
  (para un volumen con nombre de Docker en vez de bind mount, cambia el
  origen a `-v <volumen_viejo>:/from` y usa `cp -a /from/. /to/`); si el
  contenedor está corriendo, avisa al usuario y pide confirmación antes
  de tocar datos en uso.
- **Archivos/carpetas obsoletos que ya no aplican tras la migración**
  (ej. un `compose.yml` viejo en un formato distinto, un `.env` con
  variables que ya no existen en el template) — bórralos, no los dejes
  como reliquia; si tienen datos que no estén ya respaldados en otro
  lado, avisa antes de borrar.

Termina esta limpieza siempre con `docker compose config` (o el
`up -d` si el usuario lo pide) para confirmar que el resultado final
arranca correctamente, no solo que los archivos quedaron bonitos.

### 1c. Hacer que la config del stack lea las credenciales del entorno (evita desincronización)

La causa más común de romper el sitio tras tocar el `.env` es que el
archivo de config del stack (`configuration.php` en Joomla, `wp-config.php`
en WordPress, `settings.php` en Drupal — Laravel ya usa `.env` nativo así
que no aplica) tenga las credenciales de DB escritas literalmente y
queden desincronizadas del `.env` en cuanto alguien cambia una sin
acordarse de la otra. Todos los templates de compose ya pasan
`DB_HOST`/`DB_USER`/`DB_PASSWORD`/`DB_NAME` como variables de entorno
al contenedor `php` — haz que el archivo de config las lea de ahí en
vez de tener el valor duplicado a mano:

- **Joomla** (`configuration.php`, clase `JConfig` con propiedades
  públicas — no acepta `getenv()` como valor por defecto porque debe
  ser una expresión constante): agrega un `__construct()` al final de
  la clase que sobreescriba `$this->host/user/password/db` con
  `getenv('DB_HOST') ?: $this->host`, etc. Los valores literales que
  ya trae el archivo quedan como fallback.
- **WordPress** (`wp-config.php`): reemplaza los `define('DB_HOST', '...')`
  por `define('DB_HOST', getenv('DB_HOST') ?: 'mariadb')` (WordPress sí
  permite expresiones normales ahí, no es una propiedad de clase).
- **Drupal** (`settings.php`): en el array `$databases['default']['default']`,
  usa `getenv('DB_HOST') ?: 'mariadb'` por cada clave en vez del valor
  literal.
- **Moodle** (`config.php`): mismo patrón, `getenv('DB_HOST') ?: 'mariadb'`
  para `$CFG->dbhost`, `$CFG->dbuser`, `$CFG->dbpass`, `$CFG->dbname`.

Si el archivo de config del proyecto destino ya existe con credenciales
hardcodeadas al momento de correr este skill, aplica este patrón ahí en
vez de dejarlo tal cual — es parte de dejar el proyecto en el estándar,
no un paso opcional.

### 2. Ajustar el `.env` con los valores reales

Reemplaza en el `.env` generado (no en `.env.example`):
- `PROJECT_NAME` con el nombre que dio el usuario
- Passwords de DB con valores fuertes generados (no dejes el
  placeholder en el `.env` real)
- Puertos si el usuario menciona que ya tiene algo corriendo en 8000/9000/8025

Verifica que `.env` esté en `.gitignore` del proyecto destino (créalo o
añade la línea si falta) — `.env.example` sí se versiona.

### 3. Virtualhost del servidor + certbot (solo si el usuario lo pidió en 0.6)

Los templates viven en `templates/vhost/`:

```
templates/vhost/
  nginx.conf.tpl
  apache.conf.tpl
```

- Copia el `.tpl` correspondiente reemplazando `{{DOMAIN}}` (dominio
  dado en 0.6), `{{HTTP_PORT}}` con el puerto confirmado en 0.6 (por
  default el mismo `HTTP_PORT` del `.env`, pero puede ser otro si el
  usuario está enlazando este dominio a un puerto distinto) y
  `{{DEPLOY_PATH}}` con la ruta dada en 0.7 (el `location`/`Alias` del
  acme-challenge para certbot webroot apunta a `{{DEPLOY_PATH}}/app`)
  al archivo
  destino: siempre `./deploy/{nginx|apache}/{{DOMAIN}}.conf` dentro del
  proyecto — la ruta de instalación en el servidor real depende de la
  distro confirmada en 0.6 (ver abajo).
- Toda config relacionada a Docker vive bajo `./deploy/` — es la
  carpeta estándar del usuario para esto (nginx/extra.conf, .htpasswd,
  y ahora también el vhost del host), nunca crear una carpeta `docker/`
  ni ninguna otra alterna para este propósito.
- Ambos templates son reverse proxy hacia `127.0.0.1:{{HTTP_PORT}}`
  (el puerto que `compose.yml` expone del contenedor `nginx` de
  wodby) — el servidor web del host no sirve el docroot directamente.
- No los coloques en `/etc/nginx`, `/etc/httpd` o `/etc/apache2`
  directamente — este skill solo genera el archivo en el proyecto
  (`./deploy/...`); copiarlo al sistema y recargar el servicio es un
  paso manual del usuario en el servidor (indícalo en `STEPS.md`, no lo
  ejecutes tú salvo que el usuario esté en ese mismo servidor y lo pida
  explícitamente).

**Instalación del vhost según la distro** (confirmada en 0.6): las
rutas, el nombre del paquete/servicio y el comando de habilitación
difieren entre familia Debian y familia RedHat — nunca asumas una por
la otra. Añade a `STEPS.md` el bloque correspondiente:

```bash
# --- Debian / Ubuntu ---
# nginx
sudo cp ./deploy/nginx/{{DOMAIN}}.conf /etc/nginx/sites-available/{{DOMAIN}}.conf
sudo ln -s /etc/nginx/sites-available/{{DOMAIN}}.conf /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# apache (paquete/servicio apache2)
sudo cp ./deploy/apache/{{DOMAIN}}.conf /etc/apache2/sites-available/{{DOMAIN}}.conf
sudo a2ensite {{DOMAIN}}.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
```

```bash
# --- RHEL / Rocky Linux / AlmaLinux / CentOS ---
# nginx (sin sites-available/sites-enabled: el archivo se coloca
# directo en conf.d y se incluye automáticamente)
sudo cp ./deploy/nginx/{{DOMAIN}}.conf /etc/nginx/conf.d/{{DOMAIN}}.conf
sudo nginx -t && sudo systemctl reload nginx

# apache (paquete/servicio httpd, no apache2; tampoco existe a2ensite,
# también se coloca directo en conf.d)
sudo cp ./deploy/apache/{{DOMAIN}}.conf /etc/httpd/conf.d/{{DOMAIN}}.conf
sudo apachectl configtest && sudo systemctl reload httpd

# SELinux (Enforcing por default en Rocky/RHEL) bloquea el reverse
# proxy hacia 127.0.0.1:{{HTTP_PORT}} salvo que se permita:
sudo setsebool -P httpd_can_network_connect on
```

Si el usuario tiene firewall activo, añade también el comando de abrir
puertos 80/443 según la distro (`sudo ufw allow 'Nginx Full'` /
`'Apache Full'` en Debian-Ubuntu con ufw; `sudo firewall-cmd
--permanent --add-service=http --add-service=https && sudo
firewall-cmd --reload` en RHEL/Rocky con firewalld) — solo si el
usuario confirma que el firewall del host está activo, no lo asumas.

**Certbot: solo el certificado, nunca el vhost** — el usuario prefiere
generar el vhost con este skill y gestionar el certificado
manualmente, así que **nunca uses los plugins `--nginx`/`--apache` de
certbot** (reescriben el vhost automáticamente y pisarían el archivo
generado en este paso). Usa siempre `certonly` en modo webroot, y deja
que el usuario agregue a mano las líneas `ssl_certificate`/
`SSLCertificateFile` al vhost una vez tenga el certificado.

Instalación de certbot según la distro (si el usuario no lo tiene
instalado — pregúntale, no lo instales tú sin avisar):

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y certbot

# RHEL / Rocky Linux / AlmaLinux / CentOS (requiere EPEL)
sudo dnf install -y epel-release
sudo dnf install -y certbot
```

Comando para obtener el certificado (mismo en ambas distros, certbot
es el mismo binario, solo cambia `DEPLOY_PATH`/docroot):

```bash
sudo certbot certonly --webroot -w {{DEPLOY_PATH}}/app -d {{DOMAIN}} -d www.{{DOMAIN}}
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
`drush updb`/`wp core update-db`/`admin/cli/upgrade.php`/actualización
de extensiones Joomla vía backend) dejando activo solo el comando del
stack elegido, comentando los otros o eliminándolos.

Avisa al usuario qué secrets/variables debe configurar en el
repositorio (`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_SSH_KEY`,
`DEPLOY_PATH`) — este skill no los configura, solo genera el pipeline.
Dile explícitamente el valor que debe poner en `DEPLOY_PATH` (la ruta
del paso 0.7), para que no quede como incógnita al momento de crear el
secret/variable en GitHub/Bitbucket.

### 5. Generar `STEPS.md`

Copia `templates/STEPS.md.tpl` a `./STEPS.md` en la raíz, rellenando:
- `{{PROJECT_NAME}}`, `{{STACK}}`, `{{DB_ENGINE}}` (nombre real del motor: `mariadb`, `mysql`, `postgres`, etc. — la carpeta de datos es `./{{DB_ENGINE}}/data`)
- `{{HTTP_PORT}}`, `{{ADMINER_PORT}}` con los
  valores reales del `.env`
- Si en 0.8 el usuario dijo que no usará Adminer, elimina del
  `STEPS.md` generado la línea "Adminer (DB): http://localhost:...",
  no la dejes con un puerto que ya no existe en el `.env`
- `{{POST_STEPS}}` con los comandos específicos del stack elegido
  (instalación inicial de Drupal/WordPress/Moodle, o
  `artisan migrate`/`artisan key:generate` en Laravel)
- `{{CI_FILE}}` con la ruta del archivo de CI/CD generado en el paso 4
- `{{DEPLOY_PATH}}` con la ruta dada en 0.7 (carpeta del proyecto en el
  servidor) — úsala también dentro de los comandos de instalación del
  vhost (paso 3) y en el `-w {{DEPLOY_PATH}}/app` del comando certbot,
  para que quede claro dónde vive todo, ya que varía según
  cliente/servidor
- Si el usuario pidió virtualhost (0.6): `{{VHOST_SERVER}}` (nginx o
  apache), `{{VHOST_DISTRO}}` (Debian/Ubuntu o RHEL/Rocky, confirmada
  en 0.6) y `{{VHOST_STEPS}}` con la ruta del archivo generado en el
  paso 3 y el bloque de instalación correspondiente a esa distro (paso
  3: rutas `sites-available`+`a2ensite` en Debian/Ubuntu vs `conf.d`
  directo + `setsebool` en RHEL/Rocky), más el comando
  `{{CERTBOT_CMD}}` (`certonly --webroot`, nunca el plugin
  `--nginx`/`--apache`)
- Si el usuario **no** pidió virtualhost, elimina del `STEPS.md`
  generado las secciones 6 y 7 del template (virtualhost y certbot) —
  no las dejes con placeholders sin rellenar

### 6. Generar `COMMANDS.md`

Copia `templates/COMMANDS.md.tpl` a `./COMMANDS.md` en la raíz,
rellenando `{{PROJECT_NAME}}`, `{{STACK}}`, `{{DB_ENGINE}}`, `{{DB_USER}}`,
`{{DB_PASSWORD}}`, `{{DB_NAME}}` con los valores reales del `.env`, y
`{{STACK_COMMANDS}}` con comandos propios del stack elegido, por ejemplo:

- Drupal: `docker compose exec php drush cr`, `drush sql-dump`, `drush updb`
- Laravel: `docker compose exec php php artisan tinker`, `artisan queue:restart`, `artisan cache:clear`
- WordPress: `docker compose exec php wp cache flush`, `wp db export`
- Moodle: `docker compose exec php php admin/cli/purge_caches.php`
- Joomla: `docker compose exec php php cli/joomla.php cache:clear`, backup vía Akeeba o `mysqldump` manual

Este archivo es para el día a día (entrar al contenedor, backup/restore
de la DB, ver logs) — no lo confundas con `STEPS.md`, que es la guía de
puesta en marcha inicial y despliegue.

El template ya trae el comando `sudo ss -tulpn | grep LISTEN` para ver
qué puertos están libres/ocupados en el servidor — el usuario lo
necesita siempre antes de fijar `HTTP_PORT`/`ADMINER_PORT`/etc. en el
`.env`, así que nunca lo quites de `COMMANDS.md`.

### 7. Resumen final

Termina siempre listando qué archivos se crearon o modificaron
(`compose.yml`, `.env`, `.env.example`, el archivo de CI/CD, `STEPS.md`,
`COMMANDS.md`, cambios en `.gitignore`) y el próximo comando a correr
(`docker compose up -d`).

## Instrucciones especiales

- **Nunca uses `latest` como tag de imagen** en los templates — todos
  fijan una versión concreta; si el usuario no especifica, deja la que
  trae el `.tpl`.
- **Nunca inventes un tag con sufijo de build** (ej.
  `7.3-dev-4.36.4`, `1.25-5.13.3`) sin verificarlo — los tags de wodby
  cambian de sufijo constantemente al salir nuevas builds y un sufijo
  viejo o adivinado da `manifest unknown` al hacer `docker compose up`.
  Antes de fijar o cambiar cualquier `*_TAG` en un `.env` real, verifica
  que exista con `docker manifest inspect wodby/<imagen>:<tag>` (sale
  limpio si existe, error si no) — o usa el tag simple sin sufijo (ej.
  `7.3`, `1.25`, `10.11`, `4.8`), que sí es estable y wodby siempre
  mantiene apuntando a la build más reciente de esa versión. Si detectas
  que un stack específico ya no tiene builds recientes de la versión de
  PHP que necesita (ej. wodby/php dejó de publicar 7.x), avisa al
  usuario explícitamente — no fuerces un tag que no existe ni cambies
  de versión de PHP sin decírselo, porque puede romper compatibilidad
  con el código del proyecto.
- **Código en `./app`, datos por motor en `./<motor>/data`** — ambos
  como carpetas visibles dentro de la raíz del proyecto (nunca
  volúmenes con nombre gestionados por Docker fuera del proyecto), para
  que todo (código + datos) viva en una sola carpeta portable y se
  pueda respaldar con un simple `cp`/`tar` de la carpeta. Cada motor de
  base de datos tiene su propia carpeta de nivel raíz nombrada como el
  motor real (`./mariadb/data`, `./mysql/data`, `./postgres/data` —
  nunca `./data/mariadb`, el nombre del motor va primero) y esa
  subcarpeta siempre se mapea con bind mount (`- ./<motor>/data:<ruta
  interna>`), nunca con un volumen nombrado de Docker. Datos de
  aplicación que no son de un motor de DB (ej. `moodledata`) van en su
  propia carpeta de nivel raíz con su propio nombre (`./moodledata`),
  sin el patrón `<nombre>/data`. Un volumen nombrado solo se justifica
  cuando el dato es realmente efímero/interno
  (ej. cache de Redis sin persistencia) y no necesita respaldo ni
  portabilidad; en ese caso, ni siquiera declares un volumen, deja el
  servicio sin `volumes:`.
- **`./<motor>/init:/docker-entrypoint-initdb.d` siempre mapeado en el
  servicio de base de datos**, sin importar el motor (MariaDB, MySQL,
  Postgres) ni el stack — es la carpeta estándar para un dump inicial
  que se auto-importa la primera vez que el contenedor arranca con
  `./<motor>/data` vacío. Nunca lo omitas por default; solo se puede
  quitar si el usuario dice explícitamente que no quiere ningún dump
  inicial automático.
- **Moodle no tiene imagen oficial de wodby tan estable** como
  drupal-php/wordpress-php — el template usa `wodby/php` genérico y
  deja una nota; verifica con el usuario si prefiere una imagen
  alternativa antes de dar el despliegue por cerrado.
- **No sobrescribas un `compose.yml` o `.env` ya existente sin avisar**
  — si ya existen en la carpeta destino, muéstraselos al usuario y
  confirma antes de reemplazar.
- **No inventes credenciales de servidor real** para el CI/CD — deja
  siempre placeholders de secrets/variables, nunca valores hardcodeados.
