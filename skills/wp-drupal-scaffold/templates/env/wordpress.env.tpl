# ==========================================================================
# .env.example — {{PROJECT_NAME}} (WordPress, local)
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
TABLE_PREFIX=wp_

WP_ADMIN_USER=admindev
WP_ADMIN_PASSWORD=CAMBIA_ESTA_PASSWORD
WP_ADMIN_EMAIL=admindev@local.com
WP_TITLE={{PROJECT_NAME}} (local)

WP_DEBUG=true
WP_DEBUG_LOG=true
WP_DEBUG_DISPLAY=false

# UID/GID del usuario del host (id -u / id -g) — evita archivos root en bind mounts.
HOST_UID=1000
HOST_GID=1000
