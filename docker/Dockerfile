FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    mysql-client \
    icu-dev \
    oniguruma-dev \
    linux-headers

# Install PHP extensions
RUN docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        intl \
        opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Install dependencies (production)
RUN if [ -f composer.json ]; then \
    composer install --no-dev --optimize-autoloader --no-interaction; \
fi

# Set permissions
RUN chown -R www-data:www-data /var/www/html/var || true

EXPOSE 9000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD php-fpm -t || exit 1

CMD ["php-fpm"]
