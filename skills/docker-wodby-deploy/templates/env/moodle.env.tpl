PROJECT_NAME=mi_proyecto_moodle

# --- Puertos expuestos en el host ---
HTTP_PORT=8000
ADMINER_PORT=9000
MAILHOG_PORT=8025

# --- Rutas de volúmenes, relativas a este compose.yml ---
# Ruta del docroot de Moodle dentro del repo
PROJECT_ROOT=./app
# Ruta de los datos de MariaDB, dentro de la misma carpeta del proyecto
DB_DATA_PATH=./mariadb/db-data
# Ruta de moodledata, dentro de la misma carpeta del proyecto
MOODLEDATA_PATH=./moodledata
# Ruta de backups (archivos y BD), montada en app y db como /backups
BACKUPS_PATH=./backups

# --- Tags de imágenes wodby (fijar versión exacta, nunca "latest"; ---
# --- verificar disponibilidad real en hub.docker.com/u/wodby)      ---
PHP_TAG=8.2-dev-4.36.4
NGINX_TAG=1.25-5.13.3
MARIADB_TAG=10.11-3.13.4
ADMINER_TAG=4-3.13.4

# --- Base de datos (debe coincidir con config.php de Moodle) ---
DB_NAME=moodle
DB_USER=moodle
DB_PASSWORD=CAMBIA_ESTA_PASSWORD
DB_ROOT_PASSWORD=CAMBIA_ESTA_PASSWORD_ROOT

# --- PHP ---
PHP_XDEBUG=0
