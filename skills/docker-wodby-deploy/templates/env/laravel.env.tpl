PROJECT_NAME=mi_proyecto_laravel

# --- Puertos expuestos en el host ---
HTTP_PORT=8000
ADMINER_PORT=9000

# --- Tags de imágenes wodby (fijar versión exacta, nunca "latest") ---
PHP_TAG=8.2
NGINX_TAG=1.25
MARIADB_TAG=10.11
ADMINER_TAG=4.8
REDIS_TAG=7

# --- Base de datos (debe coincidir con DB_* de tu .env de Laravel) ---
DB_NAME=laravel
DB_USER=laravel
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD_ROOT

# --- PHP ---
PHP_XDEBUG=0
