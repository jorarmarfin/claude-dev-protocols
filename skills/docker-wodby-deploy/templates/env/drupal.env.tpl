PROJECT_NAME=mi_proyecto_drupal

# --- Puertos expuestos en el host ---
HTTP_PORT=8000
ADMINER_PORT=9000
MAILHOG_PORT=8025

# --- Tags de imágenes wodby (fijar versión exacta, nunca "latest") ---
PHP_TAG=8.2
NGINX_TAG=1.25
MARIADB_TAG=10.11
ADMINER_TAG=4.8

# --- Base de datos ---
DB_NAME=drupal
DB_USER=drupal
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD_ROOT

# --- PHP ---
PHP_XDEBUG=0
