PROJECT_NAME=mi_proyecto_joomla

# --- Puertos expuestos en el host ---
HTTP_PORT=8000
ADMINER_PORT=9000

# --- Tags de imágenes wodby (fijar versión exacta, nunca "latest"; ---
# --- verificar disponibilidad real en hub.docker.com/u/wodby)      ---
PHP_TAG=7.3
NGINX_TAG=1.25
MARIADB_TAG=10.11
ADMINER_TAG=4.8

# --- Base de datos (debe coincidir con configuration.php de Joomla) ---
DB_NAME=joomla
DB_USER=joomla
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD_ROOT

# --- PHP ---
PHP_XDEBUG=0
