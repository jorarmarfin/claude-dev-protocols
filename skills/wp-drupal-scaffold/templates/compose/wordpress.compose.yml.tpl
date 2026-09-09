# ==========================================================================
# Entorno local — {{PROJECT_NAME}} (WordPress, instalación limpia)
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
      # Si se coloca un dump en ./sql.init/, el entrypoint lo importa solo
      # la primera vez (./mysql vacío). Acepta .sql y .sql.gz.
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
      TABLE_PREFIX: ${TABLE_PREFIX:-wp_}
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
      LOCAL_SCHEME: ${LOCAL_SCHEME:-https}
      WP_DEBUG:         ${WP_DEBUG:-true}
      WP_DEBUG_LOG:     ${WP_DEBUG_LOG:-true}
      WP_DEBUG_DISPLAY: ${WP_DEBUG_DISPLAY:-false}
    volumes:
      - ./wordpress:/var/www/html
      - ./docker/wordpress/wp-config.local.php:/var/www/html/wp-config.php:ro
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/zz-{{PROJECT_NAME}}.ini:ro
    networks: [{{PROJECT_NAME}}]

  # ------------------------------------------------------------------------
  # nginx
  # ------------------------------------------------------------------------
  nginx:
    image: nginx:1.27-alpine
    container_name: {{PROJECT_NAME}}-nginx
    restart: unless-stopped
    depends_on: [php]
    environment:
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
    volumes:
      - ./wordpress:/var/www/html:ro
      - ./docker/nginx/default.conf.template:/etc/nginx/templates/default.conf.template:ro
      - ./docker/nginx/security-headers.conf:/etc/nginx/snippets/security-headers.conf:ro
      - ./certs:/etc/nginx/certs:ro
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
    networks: [{{PROJECT_NAME}}]

  # ------------------------------------------------------------------------
  # wp-cli — comandos de administración
  # Uso:  docker compose run --rm wpcli wp plugin list
  # ------------------------------------------------------------------------
  wpcli:
    build:
      context: ./docker/php
      args:
        PHP_VERSION: ${PHP_VERSION:-8.3}
        HOST_UID:    ${HOST_UID:-1000}
        HOST_GID:    ${HOST_GID:-1000}
    container_name: {{PROJECT_NAME}}-wpcli
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
      TABLE_PREFIX: ${TABLE_PREFIX:-wp_}
      LOCAL_DOMAIN: ${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}
      LOCAL_SCHEME: ${LOCAL_SCHEME:-https}
      WP_ADMIN_USER:     ${WP_ADMIN_USER:-admindev}
      WP_ADMIN_PASSWORD: ${WP_ADMIN_PASSWORD:-admindev_local}
      WP_ADMIN_EMAIL:    ${WP_ADMIN_EMAIL:-admindev@local.com}
      WP_TITLE:          ${WP_TITLE:-{{PROJECT_NAME}} (local)}
    volumes:
      - ./wordpress:/var/www/html
      - ./docker/wordpress/wp-config.local.php:/var/www/html/wp-config.php:ro
      - ./docker/php/php.ini:/usr/local/etc/php/conf.d/zz-{{PROJECT_NAME}}.ini:ro
      - ./scripts:/scripts:ro
    # Sin entrypoint propio: así `docker compose run --rm wpcli wp <cmd>` no
    # duplica el binario (con entrypoint:["wp"] quedaría "wp wp <cmd>").
    command: ["wp", "--info"]
    networks: [{{PROJECT_NAME}}]

networks:
  {{PROJECT_NAME}}:
    driver: bridge
