PROJECT_NAME=mi_proyecto_moodle

# --- Puertos expuestos en el host ---
HTTP_PORT=8000
ADMINER_PORT=9000
MAILHOG_PORT=8025

# --- Tags de imágenes wodby (fijar versión exacta, nunca "latest"; ---
# --- verificar disponibilidad real en hub.docker.com/u/wodby)      ---
PHP_TAG=8.2
NGINX_TAG=1.25
MARIADB_TAG=10.11
ADMINER_TAG=4.8

# --- Base de datos (debe coincidir con config.php de Moodle) ---
DB_NAME=moodle
DB_USER=moodle
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD_ROOT

# --- PHP ---
PHP_XDEBUG=0
