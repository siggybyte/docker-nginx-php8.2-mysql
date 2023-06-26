# Base image
FROM php:8.2-fpm

# Set the working directory
WORKDIR /var/www/html

# Install system dependencies
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
    cron \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo_mysql \
    gd

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Install Certbot
RUN apt-get update && apt-get install -y \
    certbot \
    python3-certbot-nginx \
    && rm -rf /var/lib/apt/lists/*

# Generate self-signed SSL certificate and private key
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost" \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

# Configure Nginx
COPY nginx.conf /etc/nginx/sites-available/default

# Configure phpMyAdmin
RUN curl -o phpmyadmin.tar.gz -SL https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
    && tar -xzf phpmyadmin.tar.gz --strip-components=1 -C /var/www/html \
    && rm phpmyadmin.tar.gz

# Create a cron job for Certbot SSL renewal
RUN echo "0 12 * * * certbot renew --nginx >> /var/log/cron.log 2>&1" >> /etc/crontab

# Expose ports
EXPOSE 80
EXPOSE 443

# Start services
CMD service php8.2-fpm start && service mysql start && cron && nginx -g "daemon off;"
