FROM ubuntu:24.04

ARG OLS_VERSION
ARG PHP_VERSION
ENV DRUSHVER=13

RUN apt-get update && apt-get install wget curl cron tzdata unzip apt-utils -y

RUN wget https://openlitespeed.org/packages/openlitespeed-$OLS_VERSION.tgz && \
    tar xzf openlitespeed-$OLS_VERSION.tgz && cd openlitespeed && ./install.sh && \
    echo 'cloud-docker' > /usr/local/lsws/PLAT && rm -rf /openlitespeed && rm /openlitespeed-$OLS_VERSION.tgz

RUN wget -O - https://repo.litespeed.sh | bash

RUN apt-get install mysql-client $PHP_VERSION $PHP_VERSION-common $PHP_VERSION-mysql $PHP_VERSION-opcache \
    $PHP_VERSION-curl $PHP_VERSION-imagick $PHP_VERSION-intl -y

RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then apt-get install $PHP_VERSION-json -y; fi"]

RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh

RUN ln -s /usr/local/lsws/$PHP_VERSION/bin/php /usr/bin/php

RUN wget -O -  https://get.acme.sh | sh

EXPOSE 7080
ENV PATH="/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin"

ADD docker.conf /usr/local/lsws/conf/templates/docker.conf
ADD setup_docker.sh /usr/local/lsws/bin/setup_docker.sh
ADD httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
ADD htpasswd /usr/local/lsws/admin/conf/htpasswd

RUN /usr/local/lsws/bin/setup_docker.sh && rm /usr/local/lsws/bin/setup_docker.sh
RUN chown 994:994 /usr/local/lsws/conf -R
RUN cp -RP /usr/local/lsws/conf/ /usr/local/lsws/.conf/
RUN cp -RP /usr/local/lsws/admin/conf /usr/local/lsws/admin/.conf/
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp8; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp8* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp8 /usr/local/lsws/fcgi-bin/lsphp; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/$PHP_VERSION/bin/lsphp /usr/local/lsws/fcgi-bin/lsphp7; fi"]
RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then ln -sf /usr/local/lsws/fcgi-bin/lsphp7 /usr/local/lsws/fcgi-bin/lsphp; fi"]

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

RUN composer global require drush/drush:^${DRUSHVER} --with-all-dependencies -W -q && \
    wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar -q && \
    chmod +x drush.phar && \
    mv drush.phar /usr/bin/drush

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /var/www/vhosts/
