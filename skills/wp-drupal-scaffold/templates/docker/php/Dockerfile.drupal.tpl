# ==========================================================================
# PHP-FPM — {{PROJECT_NAME}} (Drupal)
# ==========================================================================
ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        libicu-dev \
        libonig-dev \
        libpq-dev \
        default-mysql-client \
        less \
        git \
        unzip \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        intl \
        exif \
        bcmath \
        opcache

# Composer, para instalar Drupal core + drush vía composer.json del proyecto
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Alinea el uid/gid de www-data con el del host para que los archivos que
# escriba Drupal (sites/default/files, config sync) queden accesibles sin sudo.
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN if [ "${HOST_UID}" != "33" ]; then \
        groupmod -o -g "${HOST_GID}" www-data && \
        usermod  -o -u "${HOST_UID}" -g "${HOST_GID}" www-data; \
    fi

WORKDIR /var/www/html
