FROM php:7.2-apache

LABEL maintainer="nizovtsevnv@gmail.com"

WORKDIR /var/www/html

COPY php.custom.ini /usr/local/etc/php/conf.d

RUN apt-get update && apt-get install -y cron libc-client-dev libcurl4-openssl-dev \
    libfreetype6-dev libjpeg62-turbo-dev libkrb5-dev libldap2-dev \
    libmcrypt-dev libpng-dev libpq-dev libssl-dev libxml2-dev zlib1g-dev \
    && apt-get clean
        
RUN pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) fileinfo gd imap ldap \
       mysqli pdo_mysql pdo_pgsql soap

RUN curl https://codeload.github.com/salesagility/SuiteCRM/zip/master -o /tmp/master.zip \
    && unzip /tmp/master.zip \
    && SuiteCRM-master/* . \
    && rm -rf SuiteCRM-master /tmp/master.zip \
    && chown -R www-data:www-data . \
    && chmod -R 755 . \
    && echo "* * * * * cd /var/www/html; php -f cron.php > /dev/null 2>&1 " | crontab -

VOLUME /var/www/html/upload
VOLUME /var/www/html/conf.d

EXPOSE 80
