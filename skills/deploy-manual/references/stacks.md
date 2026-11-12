# Referencia por stack (nativo, Ubuntu/Debian)

## Comunes
- Usuario deploy no-root con sudo; `ufw allow OpenSSH 'Nginx Full'`; `apt update && apt upgrade -y`.
- Certbot: `sudo apt install certbot python3-certbot-nginx` → `sudo certbot --nginx -d <DOMINIO>` (apache: `python3-certbot-apache`, `--apache`). Verificar `certbot renew --dry-run`.
- Verificación: `curl -I https://<DOMINIO>`, `systemctl status <servicio>`, logs en `/var/log/nginx/`.

## Django / Flask
Paquetes: `python3-venv python3-pip nginx` (+ libs de BD). Pasos: clonar → `python3 -m venv venv` → `pip install -r requirements.txt gunicorn` → `.env` → (Django) `migrate`, `collectstatic` → unit systemd `/etc/systemd/system/<app>.service` (gunicorn, socket unix o 127.0.0.1:8000, User/Group, WorkingDirectory, EnvironmentFile) → vhost nginx proxy_pass + `location /static/` → `systemctl enable --now`. Flask: `gunicorn "app:create_app()"`. uwsgi solo si el usuario lo pide.

## Laravel
PHP + extensiones (`php-fpm php-mbstring php-xml php-curl php-zip php-mysql php-gd php-intl`), composer, nginx/apache. Pasos: clonar → `composer install --no-dev -o` → `.env` + `php artisan key:generate` → `migrate --force` → `storage:link` → permisos `storage` y `bootstrap/cache` a `www-data` → `config:cache route:cache view:cache` → vhost con root `public/`. Si usa queues: supervisor/systemd; scheduler: cron `* * * * * php artisan schedule:run`. Filament en producción: el User debe implementar `FilamentUser` (si no, 403).

## WordPress
LEMP/LAMP, BD + usuario, descargar core (wp-cli o zip), `wp-config.php`, permisos (`www-data`, 755/644, `wp-content/uploads` escribible), vhost con `try_files $uri $uri/ /index.php?$args`, SSL, cron real opcional.

## Drupal
Composer (`composer create-project`/clonar), `sites/default/settings.php` + `files/` escribible, drush, vhost con root `web/`, `drush cr`, `drush cim`/`updb` en actualizaciones, `trusted_host_patterns`.

## Joomla / Moodle
Joomla: zip/composer, `configuration.php`, permisos. Moodle: clonar rama estable, `moodledata` fuera de webroot, php.ini (`max_input_vars=5000`), cron cada minuto, CLI install `admin/cli/install.php`.

## Node / Astro
Estático: `npm ci && npm run build` → servir `dist/` con nginx. SSR: Node LTS (nvm/nodesource), PM2 (`pm2 start`, `pm2 startup`, `pm2 save`) o systemd, nginx proxy.

## Docker (no Wodby)
Instalar Docker Engine + compose plugin, usuario en grupo `docker`, `compose.yml` con rutas relativas, `.env`, `docker compose up -d`, `docker compose logs -f`, proxy inverso en host + certbot, backups de volúmenes.
