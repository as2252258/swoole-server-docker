FROM php:8.0.6-cli

RUN apt-get update

RUN apt-get install -y libfreetype6-dev libjpeg62-turbo-dev libpng-dev git librdkafka-dev zip unzip \
        net-tools openssl libssl-dev curl libcurl4-openssl-dev iputils-ping

RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' >/etc/timezone

RUN mkdir -p /tmp/swoole

RUN pecl download swoole \
        && tar -xf swoole-* -C /tmp/swoole --strip-components=1 \
        && rm swoole-* \
        && ( \
            cd /tmp/swoole \
            && phpize \
            && ./configure --enable-openssl --enable-debug --enable-http2 --enable-swoole-json --enable-swoole-curl \
            && make -j "$(nproc)" \
            && make install \
        ) \
        && rm -r /tmp/swoole \
        && docker-php-ext-enable swoole
        
RUN git clone https://github.com/swoole/ext-serialize.git /tmp/ext-serialize \
        && ( \
            cd /tmp/ext-serialize \
            && phpize \
            && ./configure \
            && make -j "$(nproc)" \
            && make install \
        ) \
        && rm -r /tmp/ext-serialize \
        && docker-php-ext-enable swoole_serialize


RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) gd

RUN docker-php-ext-configure pdo_mysql && docker-php-ext-install -j$(nproc) pdo_mysql

RUN pecl install rdkafka && pecl install inotify && pecl install redis && docker-php-ext-enable rdkafka inotify redis

RUN mkdir /webroot/ && cd /webroot/ \
         && php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" \
         && php composer-setup.php \
         && php -r "unlink('composer-setup.php');" \
         && chmod +x composer.phar \
         && mv composer.phar /usr/local/bin/composer
         
RUN ulimit -c 0

RUN apt-get update \
        && apt-get install openssh-client -y \
        && rm -rf /var/lib/apt/lists/* \
        && echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
        && echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config
