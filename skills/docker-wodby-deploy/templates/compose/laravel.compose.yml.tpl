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
      - ./mariadb/data:/var/lib/mysql
      - ./mariadb/init:/docker-entrypoint-initdb.d

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
    volumes:
      - ./app:/var/www/html
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
      NGINX_VHOST_PRESET: laravel
    volumes:
      - ./app:/var/www/html
    ports:
      - "${HTTP_PORT}:80"

  redis:
    image: wodby/redis:${REDIS_TAG}
    container_name: "${PROJECT_NAME}_redis"

  adminer:
    image: wodby/adminer:${ADMINER_TAG}
    container_name: "${PROJECT_NAME}_adminer"
    environment:
      ADMINER_DEFAULT_DB_DRIVER: mysql
      ADMINER_DEFAULT_DB_HOST: mariadb
      ADMINER_DEFAULT_DB_NAME: ${DB_NAME}
    ports:
      - "${ADMINER_PORT}:9000"

  queue:
    image: wodby/php:${PHP_TAG}
    container_name: "${PROJECT_NAME}_queue"
    command: php artisan queue:work --tries=3 --sleep=3
    environment:
      DB_HOST: mariadb
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
      DB_NAME: ${DB_NAME}
    volumes:
      - ./app:/var/www/html
    depends_on:
      - mariadb
      - redis
