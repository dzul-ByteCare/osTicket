FROM php:8.4-apache

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

WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
