# ==========================================================================
# Entorno local — {{PROJECT_NAME}} (Drupal, instalación limpia)
# Arranque:  ./scripts/setup.sh && docker compose up -d
# ==========================================================================

name: {{PROJECT_NAME}}-local

services:

  # ------------------------------------------------------------------------
  # Base de datos
  # ------------------------------------------------------------------------
  db:
    image: mariadb:${MARIADB_VERSION:-11.4}
    container_name: {{PROJECT_NAME}}-db
    restart: unless-stopped
    user: "${HOST_UID:-1000}:${HOST_GID:-1000}"
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --pid-file=/var/lib/mysql/mysqld.pid
      - --socket=/var/lib/mysql/mysqld.sock
    environment:
      MYSQL_DATABASE:      ${DB_NAME:-{{PROJECT_NAME}}}
      MYSQL_USER:          ${DB_USER:-{{PROJECT_NAME}}}
      MYSQL_PASSWORD:      ${DB_PASSWORD:-changeme_local}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-root_local}
    volumes:
      - ./mysql:/var/lib/mysql
      # Dump opcional en ./sql.init/ (.sql o .sql.gz) — se importa solo la
      # primera vez, con ./mysql vacío. Si no hay dump, Drupal instala limpio.
      - ./sql.init:/docker-entrypoint-initdb.d:ro
    ports:
      - "127.0.0.1:${DB_EXPOSED_PORT:-3307}:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-uroot", "-p${DB_ROOT_PASSWORD:-root_local}"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 60s
    networks: [{{PROJECT_NAME}}]

  # ------------------------------------------------------------------------
  # PHP-FPM
  # ------------------------------------------------------------------------
  php:
    build:
      context: ./docker/php
      args:
        PHP_VERSION: ${PHP_VERSION:-8.3}
        HOST_UID:    ${HOST_UID:-1000}
        HOST_GID:    ${HOST_GID:-1000}
    container_name: {{PROJECT_NAME}}-php
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_NAME:      ${DB_NAME:-{{PROJECT_NAME}}}
      DB_USER:      ${DB_USER:-{{PROJECT_NAME}}}
      DB_PASSWORD:  ${DB_PASSWORD:-changeme_local}
      DB_HOST:      db
      DB_PORT:      3306
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
      LOCAL_SCHEME: ${LOCAL_SCHEME:-https}
    volumes:
      - ./drupal:/var/www/html
      - ./docker/drupal/settings.local.php:/var/www/html/sites/default/settings.local.php:ro
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/zz-{{PROJECT_NAME}}.ini:ro
    networks: [{{PROJECT_NAME}}]

  # ------------------------------------------------------------------------
  # nginx — clean URLs de Drupal (ver docker/nginx/default.conf.template)
  # ------------------------------------------------------------------------
  nginx:
    image: nginx:1.27-alpine
    container_name: {{PROJECT_NAME}}-nginx
    restart: unless-stopped
    depends_on: [php]
    environment:
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
    volumes:
      - ./drupal:/var/www/html:ro
      - ./docker/nginx/default.conf.template:/etc/nginx/templates/default.conf.template:ro
      - ./docker/nginx/security-headers.conf:/etc/nginx/snippets/security-headers.conf:ro
      - ./certs:/etc/nginx/certs:ro
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
    networks: [{{PROJECT_NAME}}]

  # ------------------------------------------------------------------------
  # drush — comandos de administración
  # Uso:  docker compose run --rm drush drush status
  # ------------------------------------------------------------------------
  drush:
    build:
      context: ./docker/php
      args:
        PHP_VERSION: ${PHP_VERSION:-8.3}
        HOST_UID:    ${HOST_UID:-1000}
        HOST_GID:    ${HOST_GID:-1000}
    container_name: {{PROJECT_NAME}}-drush
    depends_on:
      db:
        condition: service_healthy
    user: "${HOST_UID:-1000}:${HOST_GID:-1000}"
    environment:
      DB_NAME:      ${DB_NAME:-{{PROJECT_NAME}}}
      DB_USER:      ${DB_USER:-{{PROJECT_NAME}}}
      DB_PASSWORD:  ${DB_PASSWORD:-changeme_local}
      DB_HOST:      db
      DB_PORT:      3306
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
      LOCAL_SCHEME: ${LOCAL_SCHEME:-https}
      DRUPAL_ADMIN_USER:     ${DRUPAL_ADMIN_USER:-admindev}
      DRUPAL_ADMIN_PASSWORD: ${DRUPAL_ADMIN_PASSWORD:-admindev_local}
      DRUPAL_ADMIN_EMAIL:    ${DRUPAL_ADMIN_EMAIL:-admindev@local.com}
      DRUPAL_SITE_NAME:      ${DRUPAL_SITE_NAME:-{{PROJECT_NAME}} (local)}
    volumes:
      - ./drupal:/var/www/html
      - ./docker/drupal/settings.local.php:/var/www/html/sites/default/settings.local.php:ro
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/zz-{{PROJECT_NAME}}.ini:ro
      - ./scripts:/scripts:ro
    working_dir: /var/www/html
    command: ["drush", "status"]
    networks: [{{PROJECT_NAME}}]

networks:
  {{PROJECT_NAME}}:
    driver: bridge
