# ==========================================================================
# PHP-FPM — {{PROJECT_NAME}} (WordPress)
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
        default-mysql-client \
        less \
        git \
        unzip \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
        mysqli \
        gd \
        zip \
        intl \
        exif \
        bcmath \
        opcache

RUN curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp

# Alinea el uid/gid de www-data con el del host para que los archivos que
# escriba WordPress (uploads, updates de plugins) queden accesibles sin sudo.
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN if [ "${HOST_UID}" != "33" ]; then \
        groupmod -o -g "${HOST_GID}" www-data && \
        usermod  -o -u "${HOST_UID}" -g "${HOST_GID}" www-data; \
    fi

WORKDIR /var/www/html
