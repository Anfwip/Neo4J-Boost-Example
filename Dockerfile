FROM php:8.4-cli-bookworm

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        git \
        unzip \
        curl \
        cron \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libwebp-dev \
        libavif-dev \
        libfreetype6-dev \
        libxml2-dev \
        libicu-dev \
        libxslt1-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install \
        bcmath \
        exif \
        gd \
        intl \
        pdo \
        pdo_mysql \
        xsl \
        zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install --yes --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN curl -fsSL https://get.pnpm.io/install.sh | env SHELL=bash PNPM_VERSION=10.6.5 bash - \
    && ln -sf /root/.local/share/pnpm/pnpm /usr/local/bin/pnpm

WORKDIR /var/www/html

RUN git config --global --add safe.directory /var/www/html \
    && git config --global --add url."https://github.com/".insteadOf "git@github.com:" \
    && git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"

RUN composer config --global github-protocols https
