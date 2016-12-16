##############################################################
#                                                            #
#                  Moodle docker instance                    #
#                      Version 0.0.1                         #
##############################################################

FROM ubuntu:xenial
ENV TERM linux

MAINTAINER Rajesh Taneja <rajesh.taneja@gmail.com>

RUN useradd -d /home/jenkins -m jenkins \
    && useradd -d /home/rajesh -m rajesh \
    && useradd -d /home/moodle -m moodle \
	&& usermod -a -G moodle rajesh \
	&& usermod -a -G moodle jenkins

RUN apt-get update \
 && apt-get install -y apt-transport-https ca-certificates \
 && apt-get install -y language-pack-en-base software-properties-common apt-utils

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

RUN apt-get install -y software-properties-common \
 && apt-add-repository ppa:ondrej/php
RUN apt-get update

# Install libraries.
RUN apt-get install -y \
    build-essential \
    curl \
    freetds-bin \
    freetds-common \
    git \
    ghostscript \
    libaio1 \
    odbcinst \
    postgresql-contrib \
    tdsodbc \
    unixodbc \
    unzip \
    apache2 \
    php7.1 \
    php7.1-bcmath \
    php7.1-bz2 \
    php7.1-cgi \
    php7.1-cli \
    php7.1-common \
    php7.1-curl \
    php7.1-dba \
    php7.1-dev \
    php7.1-enchant \
    php7.1-gd \
    php7.1-gmp \
    php7.1-imap \
    php7.1-interbase \
    php7.1-intl \
    php7.1-json \
    php7.1-ldap \
    php7.1-mbstring \
    php7.1-mcrypt \
    php7.1-mysql \
    php7.1-odbc \
    php7.1-opcache \
    php7.1-pgsql \
    php7.1-phpdbg \
    php7.1-pspell \
    php7.1-readline \
    php7.1-recode \
    php7.1-soap \
    php7.1-sqlite3 \
    php7.1-sybase \
    php7.1-tidy \
    php7.1-xml \
    php7.1-xmlrpc \
    php7.1-xsl \
    php7.1-zip \
    php-memcached \
    php-memcache \
    php-apcu \
    php-mongodb \
    libapache2-mod-php7.1 \
    libpcre3-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    vim \
    sudo \
    unoconv \
    curl \
    apt-transport-https

# Sqlsrv on php7
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update
RUN ACCEPT_EULA=Y apt-get install -y mssql-tools \
    unixodbc-dev

# Clean docker instance.
RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Replace original freetds.conf with our's, so we can update mssql server ip.
COPY files/mssql/freetds.conf /etc/freetds/freetds.conf

# Install oracle client.
COPY files/oracle/instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
COPY files/oracle/instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
COPY files/oracle/anwser-install-oci8.txt /tmp/anwser-install-oci8.txt

# Install sqlsrv
RUN pecl install sqlsrv-4.0.7 pdo_sqlsrv-4.0.7 \
 && echo 'extension=sqlsrv.so' > /etc/php/7.1/apache2/conf.d/sqlsrv.ini \
 && echo 'extension=sqlsrv.so' > /etc/php/7.1/cli/conf.d/sqlsrv.ini \
 && echo 'extension=pdo_sqlsrv.so' > /etc/php/7.1/apache2/conf.d/pdo_sqlsrv.ini \
 && echo 'extension=pdo_sqlsrv.so' > /etc/php/7.1/cli/conf.d/pdo_sqlsrv.ini \
 && echo 'mssql.textlimit = 20971520' >> /etc/php/7.1/apache2/conf.d/sqlsrv.ini \
 && echo 'mssql.textlimit = 20971520' >> /etc/php/7.1/cli/conf.d/sqlsrv.ini \
 && echo 'mssql.textlimit = 20971520' >> /etc/php/7.1/apache2/conf.d/pdo_sqlsrv.ini \
 && echo 'mssql.textlimit = 20971520' >> /etc/php/7.1/cli/conf.d/pdo_sqlsrv.ini \
 && echo 'mssql.textsize = 20971520' >> /etc/php/7.1/apache2/conf.d/sqlsrv.ini \
 && echo 'mssql.textsize = 20971520' >> /etc/php/7.1/cli/conf.d/sqlsrv.ini \
 && echo 'mssql.textsize = 20971520' >> /etc/php/7.1/apache2/conf.d/pdo_sqlsrv.ini \
 && echo 'mssql.textsize = 20971520' >> /etc/php/7.1/cli/conf.d/pdo_sqlsrv.ini

# Install oci
RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && cd /opt/oracle/instantclient_11_2 \
 && ln -s libocci.so.11.1 libocci.so \
 && ln -s libclntsh.so.11.1 libclntsh.so \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && locale-gen "en_US.UTF-8" \
 && dpkg-reconfigure locales \
 && echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale \
 && echo "LANG=en_US.UTF-8"  >> /etc/default/locale \
 && export LC_ALL="en_US.UTF-8"

# Install solr extension.
RUN printf "\n" | pecl install solr \
 && echo 'extension=solr.so' > /etc/php/7.1/apache2/conf.d/solr.ini \
 && echo 'extension=solr.so' > /etc/php/7.1/cli/conf.d/solr.ini

# Install oracle extension.
RUN pecl install oci8-2.1.1 </tmp/anwser-install-oci8.txt \
 && echo "extension=oci8.so" >> /etc/php/7.1/apache2/conf.d/oci8.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php/7.1/apache2/conf.d/oci8.ini \
 && echo "extension=oci8.so" >> /etc/php/7.1/cli/conf.d/oci8.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php/7.1/cli/conf.d/oci8.ini

# Install redis extension. NOT YET SUPPORTED.
#RUN pecl install redis \
# && echo 'extension=redis.so' > /etc/php/7.1/apache2/conf.d/redis.ini \
# && echo 'extension=redis.so' > /etc/php/7.1/cli/conf.d/redis.ini

# APCU
RUN echo 'apc.enabled=1' >> /etc/php/7.1/cli/conf.d/apcu.ini \
 && echo 'apc.enable_cli=1' >> /etc/php/7.1/cli/conf.d/apcu.ini \
 && echo 'apc.enabled=1' >> /etc/php/7.1/apache2/conf.d/apcu.ini \
 && echo 'apc.enable_cli=1' >> /etc/php/7.1/apache2/conf.d/apcu.ini

# Limit memory usage by docker for stability.
CMD ulimit -n 1536

WORKDIR /

# COPY SCRIPTS and config.
RUN mkdir /moodledata \
 && mkdir /scripts \
 && mkdir /config

COPY files/scripts/behat.sh /scripts/behat.sh
COPY files/scripts/phpunit.sh /scripts/phpunit.sh
COPY files/scripts/lib.sh /scripts/lib.sh
COPY files/scripts/runlib.sh /scripts/runlib.sh
COPY files/scripts/moodle.sh /scripts/moodle.sh
COPY files/scripts/init.sh /scripts/init.sh
COPY files/config/config.php.template /config/config.php.template
COPY files/config/config.php.behat3.template /config/config.php.behat3.template

# Create a course and enrol users.
COPY files/backup/AllFeaturesBackup.mbz /opt/AllFeaturesBackup.mbz
COPY files/backup/enrol.php /opt/enrol.php
COPY files/backup/restore.php /opt/restore.php
COPY files/backup/users.php /opt/users.php

RUN chmod 775 /scripts/behat.sh \
 && chmod 775 /scripts/phpunit.sh \
 && chmod 775 /scripts/moodle.sh \
 && chmod 775 /scripts/init.sh \
 && chmod 777 /moodledata \
 && mkdir /shared \
 && chmod 777 /shared \
 && mkdir /shared_data \
 && chmod 777 /shared_data

RUN ln -s /scripts/behat.sh /behat
RUN ln -s /scripts/phpunit.sh /phpunit
RUN ln -s /scripts/moodle.sh /moodle_site
RUN ln -s /scripts/init.sh /init

RUN echo '%moodle  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Remove copied packages.
RUN rm /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip \
  && rm /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip \
  && rm /tmp/anwser-install-oci8.txt

# Create volumes to share faildump.
VOLUME ["/shared"]
VOLUME ["/shared_data"]

# Expose port on which web server is accessible.
EXPOSE 80
EXPOSE 22

STOPSIGNAL 9
