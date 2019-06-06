
ARG   PHP_VERSION="${PHP_VERSION:-7.3.3}"
FROM  php:${PHP_VERSION}-fpm-alpine

ADD     http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/

RUN     apk update                       && \
        \
        apk upgrade                      && \
        \
        docker-php-source extract        && \
        \
        apk add --no-cache                  \
            --virtual .build-dependencies   \
                $PHPIZE_DEPS                \
                zlib-dev                    \
                cyrus-sasl-dev              \
                git                         \
                autoconf                    \
                g++                         \
                libtool                     \
                make                        \
                pcre-dev                 && \
        \
        apk add --no-cache                  \
            tini                            \
            libintl                         \
            icu                             \
            icu-dev                         \
            libxml2-dev                     \
            postgresql-dev                  \
            freetype-dev                    \
            libjpeg-turbo-dev               \
            libpng-dev                      \
            gmp                             \
            gmp-dev                         \
            imagemagick-dev                 \
            libzip-dev                      \
            libssh2                         \
            libssh2-dev                     \
            libxslt-dev                  && \
        \
        apk add --no-cache nginx supervisor && \
        docker-php-ext-configure gd                 \
            --with-freetype-dir=/usr/include/       \
            --with-jpeg-dir=/usr/include/       &&  \
        \
        docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
            intl                                                \
            bcmath                                              \
            xsl                                                 \
            zip                                                 \
            soap                                                \
            mysqli                                              \
            pdo                                                 \
            pdo_mysql                                           \
            pdo_pgsql                                           \
            gmp                                                 \
            iconv                                               \
            sockets                                             \
            gd                                              &&  \
        \
        tar -xvzf                                                       \
            /tmp/ioncube_loaders_lin_x86-64.tar.gz                      \
            -C /tmp/                                                &&  \
        \
        mkdir -p /usr/local/php/ext/ioncube                         &&  \
        mkdir -p /run/nginx                                         &&  \
        \
        cp -a /tmp/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so      \
            /usr/local/php/ext/ioncube/ioncube_loader.so            &&  \
        \
        pecl install                                                    \
            apcu imagick                                            &&  \
        \
        docker-php-ext-enable                                           \
            apcu imagick                                            &&  \
        \
        pecl install swoole && \
        docker-php-ext-enable swoole && \
        \
        pecl install seaslog && \
        docker-php-ext-enable seaslog && \
        \
        pecl install -o -f redis && \
        docker-php-ext-enable redis && \
        \
        apk del .build-dependencies                                 &&  \
        \
        docker-php-source delete                                    &&  \
        \
        rm -rf /tmp/* /var/cache/apk/*

# set recommended PHP.ini settings
# https://secure.php.net/manual/en/opcache.installation.php
# https://secure.php.net/manual/en/apcu.configuration.php
# also, enable ioncube

ADD etc/supervisor/ /etc/supervisor/
VOLUME /var/log

EXPOSE 80 443


CMD ["/usr/bin/supervisord","-c","/etc/supervisor/supervisord.conf"]

#CMD     ["php-fpm"]
