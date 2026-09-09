# ==========================================================================
# .env.example — {{PROJECT_NAME}} (Drupal, local)
# Copiar a .env y ajustar:  cp .env.example .env
# ==========================================================================

LOCAL_DOMAIN={{PROJECT_NAME}}.localhost
LOCAL_SCHEME=https
HTTP_PORT=80
HTTPS_PORT=443

PHP_VERSION=8.3
MARIADB_VERSION=11.4

DB_NAME={{PROJECT_NAME}}
DB_USER={{PROJECT_NAME}}
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_HOST=db
DB_PORT=3306
DB_EXPOSED_PORT=3307

DRUPAL_ADMIN_USER=admindev
DRUPAL_ADMIN_PASSWORD=CAMBIA_ESTA_PASSWORD
DRUPAL_ADMIN_EMAIL=admindev@local.com
DRUPAL_SITE_NAME={{PROJECT_NAME}} (local)

# UID/GID del usuario del host (id -u / id -g) — evita archivos root en bind mounts.
HOST_UID=1000
HOST_GID=1000
