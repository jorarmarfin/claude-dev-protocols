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
    volumes:
      - ${DB_DATA_PATH}:/var/lib/mysql
      - ${BACKUPS_PATH}:/backups

  php:
    image: wodby/wordpress-php:${PHP_TAG}
    container_name: "${PROJECT_NAME}_php"
    environment:
      PHP_SENDMAIL_PATH: /usr/sbin/sendmail -t -i -S mailhog:1025
      DB_HOST: mariadb
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
      DB_DRIVER: mysql
      PHP_XDEBUG: ${PHP_XDEBUG:-0}
    volumes:
      - ${PROJECT_ROOT}:/var/www/html
      - ${BACKUPS_PATH}:/backups
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
      NGINX_VHOST_PRESET: wordpress
    volumes:
      - ${PROJECT_ROOT}:/var/www/html
    ports:
      - "${HTTP_PORT}:8080"

  adminer:
    image: wodby/adminer:${ADMINER_TAG}
    container_name: "${PROJECT_NAME}_adminer"
    environment:
      ADMINER_DEFAULT_DB_DRIVER: mysql
      ADMINER_DEFAULT_DB_HOST: mariadb
      ADMINER_DEFAULT_DB_NAME: ${DB_NAME}
    ports:
      - "${ADMINER_PORT}:9000"

  mailhog:
    image: mailhog/mailhog
    container_name: "${PROJECT_NAME}_mailhog"
    ports:
      - "${MAILHOG_PORT}:8025"
