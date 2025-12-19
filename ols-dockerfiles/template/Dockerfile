FROM ubuntu:24.04

ARG OLS_VERSION
ARG PHP_VERSION
ENV DRUSHVER=13
ARG TARGETPLATFORM

ENV LS_FD='/usr/local/lsws'
ENV PHPINI_PATH="$LS_FD/$PHP_VERSION/etc/php/*/litespeed/php.ini"

RUN apt-get update && apt-get install wget curl cron tzdata unzip apt-utils git -y

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        wget https://openlitespeed.org/packages/openlitespeed-$OLS_VERSION-x86_64-linux.tgz && \
        tar xzf openlitespeed-$OLS_VERSION-x86_64-linux.tgz && cd openlitespeed && ./install.sh && \
        echo 'cloud-docker' > $LS_FD/PLAT && rm -rf /openlitespeed && rm /openlitespeed-$OLS_VERSION-x86_64-linux.tgz; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        wget https://openlitespeed.org/packages/openlitespeed-$OLS_VERSION-aarch64-linux.tgz && \
        tar xzf openlitespeed-$OLS_VERSION-aarch64-linux.tgz && cd openlitespeed && ./install.sh && \
        echo 'cloud-docker' > $LS_FD/PLAT && rm -rf /openlitespeed && rm /openlitespeed-$OLS_VERSION-aarch64-linux.tgz; \
    else \
        echo "$TARGETPLATFORM is not supported"; \
    fi

RUN wget -O - https://repo.litespeed.sh | bash

RUN apt-get update && apt-get install mysql-client $PHP_VERSION $PHP_VERSION-common $PHP_VERSION-mysql \
    $PHP_VERSION-curl $PHP_VERSION-imagick $PHP_VERSION-redis $PHP_VERSION-memcached $PHP_VERSION-intl -y

RUN ["/bin/bash", "-c", "case \"$PHP_VERSION\" in lsphp81|lsphp82|lsphp83|lsphp84) apt-get install ${PHP_VERSION}-opcache -y ;; esac"]

RUN ["/bin/bash", "-c", "if [[ $PHP_VERSION == lsphp7* ]]; then apt-get install $PHP_VERSION-json -y; fi"]

RUN wget -O /usr/local/lsws/admin/misc/lsup.sh \
    https://raw.githubusercontent.com/litespeedtech/openlitespeed/master/dist/admin/misc/lsup.sh && \
    chmod +x /usr/local/lsws/admin/misc/lsup.sh

RUN sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' $PHPINI_PATH && \
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 1024M/g' $PHPINI_PATH && \
    sed -i 's/post_max_size = 8M/post_max_size = 1024M/g' $PHPINI_PATH && \
    sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $PHPINI_PATH

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
