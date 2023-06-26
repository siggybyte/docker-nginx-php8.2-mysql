# Use the official PHP 8.2 image
FROM php:8.2-fpm

# Set the working directory
WORKDIR /var/www/html

# Install PHP extensions and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libpng-dev \
    libjpeg-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    && docker-php-ext-install \
        pdo_mysql \
        mbstring \
        curl \
        json \
        xml \
        gd \
    && rm -rf /var/lib/apt/lists/*

# Install Certbot and dependencies
RUN apt-get update && apt-get install -y \
    certbot \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Install Certbot Nginx plugin
RUN apt-get update && apt-get install -y \
    python3-certbot-nginx \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate and private key
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost" \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

# Install Certbot cron job
COPY certbot_cron /etc/cron.d/certbot_cron
RUN chmod 0644 /etc/cron.d/certbot_cron
RUN crontab /etc/cron.d/certbot_cron
RUN touch /var/log/cron.log

# Install phpMyAdmin
RUN curl -o phpmyadmin.tar.gz -SL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
    && tar -xzf phpmyadmin.tar.gz --strip-components=1 -C /var/www/html \
    && rm phpmyadmin.tar.gz

# Configure PHP
COPY php.ini /usr/local/etc/php/php.ini

# Configure Nginx
COPY nginx.conf /etc/nginx/sites-available/default

# Expose ports
EXPOSE 80
EXPOSE 443

# Start services
CMD service php8.2-fpm start && cron && nginx -g "daemon off;"
