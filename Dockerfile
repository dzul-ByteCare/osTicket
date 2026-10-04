# osTicket 1.18.x supports PHP 8.1-8.2. PHP 8.4 removed the bundled imap extension,
# so do NOT bump this to 8.4 without moving imap to PECL.
FROM php:8.2-apache

# System dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libc-client-dev \
    libkrb5-dev \
    libxml2-dev \
    libonig-dev \
    libldap2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    zlib1g-dev \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-configure imap \
        --with-kerberos \
        --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        gd \
        intl \
        mbstring \
        zip \
        xml \
        imap \
        opcache

# Enable Apache rewrite
RUN a2enmod rewrite

# Copy osTicket source into temporary source location
COPY . /tmp/osticket

# Deploy osTicket into Apache document root
RUN rm -rf /var/www/html/* \
    && php /tmp/osticket/manage.php deploy --setup /var/www/html \
    && chown -R www-data:www-data /var/www/html

# Apache configuration
RUN printf '<Directory /var/www/html>\n\
    Options FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>\n' \
    > /etc/apache2/conf-available/osticket.conf \
    && a2enconf osticket

# Suppress Apache FQDN warning
RUN echo 'ServerName localhost' > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername

# Entrypoint keeps include/ost-config.php on a persistent volume (/data) so the
# web installer result survives redeploys.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /data

VOLUME ["/data"]

WORKDIR /var/www/html

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["apache2-foreground"]
