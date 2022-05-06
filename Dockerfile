FROM ghcr.io/roadrunner-server/roadrunner:2.9.2 AS roadrunner
FROM php:8.1-cli
ARG APPDIR

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

# USE THE RR
RUN apt update -y
RUN apt upgrade -y
RUN apt install libzip-dev -y
RUN apt install unzip -y
RUN apt install default-mysql-client -y

# install composer
WORKDIR /tmp
COPY setup-composer.sh /tmp
RUN sh setup-composer.sh
RUN mv composer.phar /usr/local/bin/composer
#

RUN mkdir -p /home/app/${APPDIR:-someapp}
RUN chown www-data:www-data /var/www
ADD --chown=www-data:www-data ./${APPDIR:-someapp} /home/app//${APPDIR:-someapp}/
ADD --chown=www-data:www-data ./.rr.yaml /home/app/${APPDIR:-someapp}
# setup for rr

# 
RUN docker-php-ext-install pdo pdo_mysql

# install ext-sockets
RUN docker-php-ext-install sockets
#
RUN mkdir -p /var/run/rr
RUN chown -R www-data:www-data /var/run/rr

WORKDIR /home/app/${APPDIR:-someapp}
USER www-data

RUN composer require spiral/roadrunner-laravel
RUN php ./artisan vendor:publish --provider='Spiral\RoadRunnerLaravel\ServiceProvider' --tag=config

#

CMD /usr/local/bin/rr serve -c /home/app/${APPDIR:-someapp}/.rr.yaml

EXPOSE 8080

