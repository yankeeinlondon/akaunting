# Multi-stage Dockerfile for Akaunting
# PHP 8.3 + Node 16 + Required Extensions

# Node build stage - Build assets separately to optimize memory usage
FROM node:16-bullseye-slim AS node-builder

WORKDIR /build

# Install build dependencies for node-sass (minimal set)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Install dependencies with reduced parallelism to save memory
RUN npm config set prefer-offline true \
    && npm config set no-audit true \
    && npm install --legacy-peer-deps --no-optional

# Copy source files needed for build
COPY resources ./resources
COPY webpack.mix.js tailwind.config.js ./

# Build assets with memory limit
RUN NODE_OPTIONS="--max-old-space-size=2048" npm run production

# Clean up to reduce image size
RUN rm -rf node_modules /root/.npm

# PHP base stage
FROM php:8.3-fpm AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    unzip \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Akaunting
# Note: ctype, fileinfo, pdo, and tokenizer are built-in to PHP 8.3
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    intl \
    gd \
    mbstring \
    pdo_mysql \
    xml \
    zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Copy built assets from node-builder stage
COPY --from=node-builder /build/public/css ./public/css
COPY --from=node-builder /build/public/js ./public/js
COPY --from=node-builder /build/public/fonts ./public/fonts
COPY --from=node-builder /build/public/mix-manifest.json ./public/mix-manifest.json

# Install PHP dependencies (without dev dependencies for production)
# Use --no-scripts to avoid running post-install scripts that require database
RUN composer install --no-dev --no-scripts --optimize-autoloader --ignore-platform-reqs

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Development stage
FROM base AS development

# Install Node.js 16 for development
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@8 \
    && rm -rf /var/lib/apt/lists/*

# Install dev dependencies
RUN composer install --optimize-autoloader --ignore-platform-reqs

# Expose port 8000 for artisan serve
EXPOSE 8000

# Start PHP-FPM and Laravel dev server
CMD php artisan serve --host=0.0.0.0 --port=8000
