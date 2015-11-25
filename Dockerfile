##############################################################
#                                                            #
#                  Moodle docker instance                    #
#                      Version 0.0.1                         #
##############################################################

# Build arguments supported.
#

FROM ubuntu:trusty
ENV TERM linux
ARG GITREPOSITORY=git://git.moodle.org/integration.git
ARG GITREMOTE=integration
ARG GITBRANCH=master
ARG IGNORECLONE=0
ENV GITREPOSITORY ${GITREPOSITORY}
ENV GITREMOTE ${GITREMOTE}
ENV GITBRANCH ${GITBRANCH}
ENV IGNORECLONE ${IGNORECLONE}


MAINTAINER Rajesh Taneja <rajesh.taneja@gmail.com>

# Install apache, php and git
RUN apt-get update \
 && apt-get install -y \
    wget
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update \
 && apt-get install -y \
    build-essential \
    curl \
    default-jdk \
    freetds-bin \
    freetds-common \
    git \
    ghostscript \
    libaio1 \
    odbcinst \
    postgresql \
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
    php5-mongo \
    php5-mysql \
    php5-odbc \
    php-pear \
    php5-pgsql \
    php5-sybase \
    php5-xmlrpc \
    supervisor \
    firefox \
    google-chrome-stable \
    xvfb \
 && apt-get clean \
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
 && pecl install oci8 </tmp/anwser-install-oci8.txt \
 && echo "extension=oci8.so" >> /etc/php5/apache2/php.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php5/apache2/php.ini \
 && echo "extension=oci8.so" >> /etc/php5/cli/php.ini \
 && echo "oci8.statement_cache_size=0" >> /etc/php5/cli/php.ini \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && locale-gen "en_AU.UTF-8" \
 && dpkg-reconfigure locales \
 && echo "LC_ALL=en_AU.UTF-8" >> /etc/environment \
 && echo "LANG=en_AU.UTF-8"  >> /etc/environment \
 && export LC_ALL="en_AU.UTF-8" \
 && apachectl restart

WORKDIR /

# COPY SCRIPTS and config.
RUN mkdir /moodle \
 && mkdir /moodledata \
 && mkdir /scripts \
 && mkdir /config \
 && mkdir /behatdrivers

COPY files/scripts/behat.sh /scripts/behat.sh
COPY files/scripts/phpunit.sh /scripts/phpunit.sh
COPY files/scripts/lib.sh /scripts/lib.sh
COPY files/scripts/docker_init.sh /scripts/docker_init.sh
COPY files/scripts/init.sh /scripts/init.sh
COPY files/config/config.php.template /config/config.php.template
COPY files/behatdrivers/selenium-server-2.47.1.jar /behatdrivers/selenium-server-2.47.1.jar
COPY files/behatdrivers/chromedriver behatdrivers/chromedriver
COPY files/behatdrivers/phantomjs behatdrivers/phantomjs

RUN chmod 775 /scripts/behat.sh \
 && chmod 775 /scripts/phpunit.sh \
 && chmod 775 /scripts/docker_init.sh \
 && chmod 775 /scripts/init.sh
RUN /etc/init.d/postgresql start \
 && /scripts/docker_init.sh

# Create volumes to share faildump.
VOLUME ["/shared"]

# Expose port on which web server is accessible.
EXPOSE 80
