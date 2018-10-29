FROM php:7.2-apache

COPY php.custom.ini /usr/local/etc/php/conf.d

RUN apt-get update && apt-get install -y cron git libc-client-dev libcurl4-openssl-dev \
    libfreetype6-dev libjpeg62-turbo-dev libkrb5-dev libldap2-dev \
    libmcrypt-dev libpng-dev libpq-dev libssl-dev libxml2-dev sudo unzip zlib1g-dev \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && apt-get clean

RUN pecl install mcrypt-1.0.1 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) fileinfo gd imap ldap zip \
       mysqli pdo_mysql pdo_pgsql soap

WORKDIR /tmp

RUN curl https://codeload.github.com/salesagility/SuiteCRM/zip/master -o /tmp/master.zip \
    && unzip /tmp/master.zip \
    && mv SuiteCRM-master/* /var/www/html \
    && rm -rf /tmp/* \
    && chown -R www-data:www-data /var/www \
    && chmod -R 755 /var/www \
    && echo "* * * * * cd /var/www/html; php -f cron.php > /dev/null 2>&1 " | crontab -

WORKDIR /var/www/html

RUN mkdir conf.d \
    && touch /var/www/html/conf.d/config.php \
    && touch /var/www/html/conf.d/config_override.php \
    && ln -s /var/www/html/conf.d/config.php config.php \
    && ln -s /var/www/html/conf.d/config_override.php config_override.php \
    && sudo -u www-data composer update --no-dev -n

VOLUME /var/www/html/upload
VOLUME /var/www/html/conf.d

EXPOSE 80
