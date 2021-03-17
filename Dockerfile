FROM php:8.0.3-cli

RUN apt-get update

RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev git librdkafka-dev zip unzip \ 
        net-tools

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) gd

RUN docker-php-ext-configure pdo_mysql && docker-php-ext-install -j$(nproc) pdo_mysql

RUN pecl install redis && pecl install swoole && pecl install rdkafka && pecl install inotify \
        && docker-php-ext-enable redis swoole rdkafka inotify

RUN mkdir /webroot/ && cd /webroot/ \
         && php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
         && php composer-setup.php \
         && php -r "unlink('composer-setup.php');" \
         && chmod +x composer.phar \
         && mv composer.phar /usr/local/bin/composer
