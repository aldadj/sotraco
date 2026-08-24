FROM php:8.3-cli

# Dépendances système (+ libpq-dev pour PostgreSQL)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libsqlite3-dev \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libonig-dev \
    curl \
    nodejs \
    npm \
    && docker-php-ext-install \
    pdo_sqlite \
    pdo_pgsql \
    pgsql \
    mbstring \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copier les fichiers Laravel nécessaires à Composer
COPY composer.json composer.lock artisan ./
COPY bootstrap ./bootstrap
COPY app ./app
COPY config ./config
COPY routes ./routes

# Installer les dépendances PHP
RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader

# Copier les dépendances JS
COPY package.json package-lock.json* ./

RUN npm install

# Copier le reste du projet
COPY . .

# Build Vite
RUN npm run build

# Préparer les dossiers Laravel
RUN mkdir -p \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache \
    database

# Permissions
RUN chmod -R 775 storage bootstrap/cache database

# Storage Laravel
RUN php artisan storage:link || true

# Script de démarrage (migrations automatiques + lancement serveur)
COPY start.sh /var/www/html/start.sh
COPY start-reverb.sh /var/www/html/start-reverb.sh
RUN chmod +x /var/www/html/start.sh /var/www/html/start-reverb.sh

EXPOSE 10000

CMD ["/var/www/html/start.sh"]