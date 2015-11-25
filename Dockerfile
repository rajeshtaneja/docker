##############################################################
#                                                            #
#                  Moodle docker instance                    #
#                      Version 0.0.1                         #
##############################################################

# Build arguments supported.
#

FROM ubuntu:precise
ENV TERM linux

MAINTAINER Rajesh Taneja <rajesh.taneja@gmail.com>

RUN useradd -d /home/jenkins -m jenkins \
    && useradd -d /home/rajesh -m rajesh \
    && useradd -d /home/moodle -m moodle \
	&& usermod -a -G moodle rajesh \
	&& usermod -a -G moodle jenkins

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Add php repo to use.
RUN apt-get update \
 && apt-get install -y python-software-properties \
 && apt-add-repository ppa:ondrej/php5-oldstable
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
    php5 \
    php5-cli \
    php5-curl \
    php5-dev \
    php5-gd \
    php5-intl \
    php5-json \
    php5-mysql \
    php5-odbc \
    php-pear \
    php5-pgsql \
    php5-sybase \
    php5-xmlrpc \
    php5-memcache \
    php5-memcached \
    libpcre3-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    vim \
    sudo

#COPY files/unoconv_0.7.deb /tmp/unoconv_0.7.deb
#RUN apt-get -y remove unoconv
#RUN apt-get install -f -y python3 python3-uno
#RUN dpkg -i /tmp/unoconv_0.7.deb

RUN apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Replace original freetds.conf with our's, so we can update mssql server ip.
COPY files/mssql/freetds.conf /etc/freetds/freetds.conf

# Install oracle client.
COPY files/oracle/instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
COPY files/oracle/instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
COPY files/oracle/anwser-install-oci8.txt /tmp/anwser-install-oci8.txt

RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && cd /opt/oracle/instantclient_11_2 \
 && ln -s libocci.so.11.1 libocci.so \
 && ln -s libclntsh.so.11.1 libclntsh.so \
 && pecl install oci8-1.4.10 </tmp/anwser-install-oci8.txt \
 && echo "extension=oci8.so" >> /etc/php5/apache2/php.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php5/apache2/php.ini \
 && echo "extension=oci8.so" >> /etc/php5/cli/php.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php5/cli/php.ini \
 && printf "\n" | pecl install solr \
 && echo 'extension=solr.so' > /etc/php5/apache2/conf.d/solr.ini \
 && echo 'extension=solr.so' > /etc/php5/cli/conf.d/solr.ini \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && locale-gen "en_AU.UTF-8" \
 && dpkg-reconfigure locales \
 && echo "LC_ALL=en_AU.UTF-8" >> /etc/environment \
 && echo "LANG=en_AU.UTF-8"  >> /etc/environment \
 && export LC_ALL="en_AU.UTF-8" \
 && apachectl restart

# Limit memory usage by docker for stability.
CMD ulimit -n 1536

WORKDIR /

# COPY SCRIPTS and config.
RUN mkdir /moodledata \
 && mkdir /scripts \
 && mkdir /config \
 && mkdir /var/www/html \
 && chmod 777 /var/www/html \
 && sed -i s#/var/www#/var/www/html#g /etc/apache2/sites-available/default

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
 && chmod 777 /shared

RUN ln -s /scripts/behat.sh /behat
RUN ln -s /scripts/phpunit.sh /phpunit
RUN ln -s /scripts/moodle.sh /moodle_site
RUN ln -s /scripts/init.sh /init

RUN echo '%moodle  ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Create volumes to share faildump.
VOLUME ["/shared"]

# Expose port on which web server is accessible.
EXPOSE 80

ENTRYPOINT ["/init"]

STOPSIGNAL 9
