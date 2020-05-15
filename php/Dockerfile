ARG PHP_VERSION=7.4.5

FROM php:${PHP_VERSION}-fpm-alpine AS custom_php_fpm

RUN apk update \
    && apk add --no-cache \
    bash=5.0.11-r1 \
    acl=2.2.53-r0 \
    curl=7.67.0-r0 \
    git=2.24.3-r0 \
    gnupg=2.2.19-r0 \
    libpq=12.2-r0  \
    libxml2-dev=2.9.10-r2 \
    libzip-dev=1.5.2-r0 \
    postgresql-dev=12.2-r0 \
    unzip=6.0-r6 \
    zip=3.0-r7

RUN docker-php-ext-configure zip -with-zip \
  && docker-php-ext-install opcache pdo pdo_pgsql zip soap json

## apcu
RUN docker-php-source extract \
    && apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install apcu-5.1.18 \
    && docker-php-ext-enable apcu \
    && apk del .phpize-deps-configure \
    && docker-php-source delete

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('sha384', 'composer-setup.php') === $(wget -q -O - https://composer.github.io/installer.sig)) { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php --install-dir /usr/local/bin --filename=composer --version=1.10.1
RUN php -r "unlink('composer-setup.php');"

RUN apk add --no-cache fcgi

HEALTHCHECK --interval=10s --timeout=3s \
    CMD \
    SCRIPT_NAME=/ping \
    SCRIPT_FILENAME=/ping \
    REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

FROM custom_php_fpm

ARG HOST_UID=${HOST_UID:-4000}
ARG HOST_USER=${HOST_USER:-nodummy}
ARG HOST_GROUP=${HOST_GROUP:-1000}

COPY php.ini /etc/php/${PHP_VERSION}/php.ini
COPY openssl.cnf /etc/ssl/openssl.cnf
COPY php-fpm-pool.conf /etc/php/${PHP_VERSION}/pool.d/www.conf
COPY opcache.ini /etc/php/${PHP_VERSION}/conf.d/opcache.ini
COPY apcu.ini /etc/php/${PHP_VERSION}/conf.d/apcu.ini

WORKDIR /home/wwwroot/src_backend
RUN if [ "${HOST_GROUP}" != "root" ]; then (addgroup -g ${HOST_GROUP} docker) ; fi
RUN if [ "${HOST_USER}" != "root" ]; then (adduser -G docker --disabled-password --uid ${HOST_UID} ${HOST_USER}) ; fi
RUN if [ "${HOST_USER}" != "root" ]; then (chown -R ${HOST_UID}:docker /home/wwwroot/src_backend) ; fi
USER ${HOST_USER}

EXPOSE 9000
CMD ["php-fpm"]
