services:
  mariadb:
    image: wodby/mariadb:${MARIADB_TAG}
    container_name: "${PROJECT_NAME}_mariadb"
    stop_grace_period: 30s
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_NAME}
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    command: --innodb_file_per_table=1 --innodb_file_format=barracuda --innodb_large_prefix=1
    volumes:
      - ./mariadb/data:/var/lib/mysql
      - ./mariadb/init:/docker-entrypoint-initdb.d

  # NOTA: wodby no publica una imagen oficial "moodle-php" con la misma
  # regularidad que drupal-php/wordpress-php. Verificar en
  # https://hub.docker.com/u/wodby cuál PHP_TAG existe antes de desplegar;
  # como fallback usa wodby/php genérico (APP_TYPE no aplica) + ajustar
  # php.ini a los requisitos de Moodle (max_input_vars, memory_limit, etc).
  php:
    image: wodby/php:${PHP_TAG}
    container_name: "${PROJECT_NAME}_php"
    environment:
      DB_HOST: mariadb
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
      DB_DRIVER: mysql
      PHP_XDEBUG: ${PHP_XDEBUG:-0}
      PHP_MAX_INPUT_VARS: 5000
      PHP_MEMORY_LIMIT: 256M
    volumes:
      - ./app:/var/www/html
      - ./moodledata:/var/www/moodledata
    depends_on:
      - mariadb

  nginx:
    image: wodby/nginx:${NGINX_TAG}
    container_name: "${PROJECT_NAME}_nginx"
    depends_on:
      - php
    environment:
      NGINX_STATIC_OPEN_FILE_CACHE: "off"
      NGINX_ERROR_LOG_LEVEL: debug
      NGINX_BACKEND_HOST: php
      NGINX_SERVER_ROOT: /var/www/html
    volumes:
      - ./app:/var/www/html
    ports:
      - "${HTTP_PORT}:80"

  adminer:
    image: wodby/adminer:${ADMINER_TAG}
    container_name: "${PROJECT_NAME}_adminer"
    environment:
      ADMINER_DEFAULT_DB_DRIVER: mysql
      ADMINER_DEFAULT_DB_HOST: mariadb
      ADMINER_DEFAULT_DB_NAME: ${DB_NAME}
    ports:
      - "${ADMINER_PORT}:9000"

  cron:
    image: wodby/php:${PHP_TAG}
    container_name: "${PROJECT_NAME}_cron"
    command: >
      sh -c "while true; do php /var/www/html/admin/cli/cron.php; sleep 60; done"
    volumes:
      - ./app:/var/www/html
      - ./moodledata:/var/www/moodledata
    depends_on:
      - mariadb
      - php
