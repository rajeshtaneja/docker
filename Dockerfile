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
ARG PHPVERSION=5.5.30
ENV GITREPOSITORY ${GITREPOSITORY}
ENV GITREMOTE ${GITREMOTE}
ENV GITBRANCH ${GITBRANCH}
ENV IGNORECLONE ${IGNORECLONE}
ENV PHPVERSION ${PHPVERSION}


MAINTAINER Rajesh Taneja <rajesh.taneja@gmail.com>

# Install apache, php and git
RUN apt-get update \
 && apt-get install -y \
    wget
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update \
 && echo "mysql-server-5.5 mysql-server/root_password password moodle" | debconf-set-selections \
 && echo "mysql-server-5.5 mysql-server/root_password_again password moodle" | debconf-set-selections \
 && apt-get build-dep -y php5 \
 && apt-get install -y php5 php5-dev php-pear autoconf automake curl libcurl3-openssl-dev build-essential libxslt1-dev re2c libxml2 libxml2-dev php5-cli bison libbz2-dev libreadline-dev \
 && apt-get install -y libfreetype6 libfreetype6-dev libpng12-0 libpng12-dev libjpeg-dev libjpeg8-dev libjpeg8  libgd-dev libgd3 libxpm4 libltdl7 libltdl-dev \
 && apt-get install -y libssl-dev openssl \
 && apt-get install -y gettext libgettextpo-dev libgettextpo0 \
 && apt-get install -y libicu-dev \
 && apt-get install -y libmhash-dev libmhash2 \
 && apt-get install -y libmcrypt-dev libmcrypt4 \
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
    firefox \
    google-chrome-stable \
    xvfb \
    python-pip \
    libmysqlclient-dev \
    libpq-dev \
    python-dev \
    apache2-dev \
    apache2-mpm-prefork \
    apache2-prefork-dev \
    aufs-tools \
    automake \
    bison \
    btrfs-tools \
    libbz2-dev \
    libcurl4-openssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    re2c \
    libpng12-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libgmp3-dev \
    libpspell-dev \
    libxpm-dev \
    libgmp-dev \
    librecode-dev \
    libicu-dev \
    libt1-dev \
    libtool \
    unixodbc-dev \
    libc-client2007e-dev \
    libpng-dev \
    libxslt-dev \
    libssl-dev \
    apache2 \
    autoconf \
    libltdl-dev \
    libreadline-dev \
    libldap2-dev \
    libtidy-dev \
    libgdbm-dev \
    libsasl2-dev \
    firebird-dev \
    lcov \
    libgd2-xpm-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h \
 && ln -s /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2 /usr/lib/liblber-2.4.so.2 \
 && ln -s /usr/lib/x86_64-linux-gnu/liblber-2.4.so.2.8.3 /usr/lib/liblber-2.4.so.2.8.3 \
 && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
 && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
 && ln -s /usr/lib/x86_64-linux-gnu/libldap_r.so /usr/lib/libldap_r.so

RUN wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-patched.tar.gz \
 && tar -xvzf freetds-patched.tar.gz \
 && cd /freetds-0.95.* \
 && ./configure --prefix=/usr/local/freetds --with-tdsver=8.0 --enable-msdblib --with-gnu-ld \
 && make && make install

# Hack for mssql library to be found for php building.
RUN touch /usr/local/freetds/include/tds.h
RUN touch /usr/local/freetds/lib/libtds.a
RUN ln -s /usr/local/freetds/lib /usr/local/freetds/lib/x86_64-linux-gnu


# Replace original freetds.conf with our's, so we can update mssql server ip.
COPY files/mssql/freetds.conf /etc/freetds/freetds.conf
COPY files/mssql/freetds.conf /usr/local/freetds/freetds.conf

# Install oracle client.
COPY files/oracle/instantclient-basic-linux.x64-11.2.0.4.0.zip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip
COPY files/oracle/instantclient-sdk-linux.x64-11.2.0.4.0.zip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip
COPY files/oracle/anwser-install-oci8.txt /tmp/anwser-install-oci8.txt

RUN unzip /tmp/instantclient-basic-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && unzip /tmp/instantclient-sdk-linux.x64-11.2.0.4.0.zip -d /opt/oracle \
 && cd /opt/oracle/instantclient_11_2 \
 && ln -s libocci.so.11.1 libocci.so \
 && ln -s libclntsh.so.11.1 libclntsh.so \
 && echo "ServerName localhost" >> /etc/apache2/apache2.conf \
 && locale-gen "en_AU.UTF-8" \
 && dpkg-reconfigure locales \
 && echo "LC_ALL=en_AU.UTF-8" >> /etc/environment \
 && echo "LANG=en_AU.UTF-8"  >> /etc/environment \
 && export LC_ALL="en_AU.UTF-8" \
 && apachectl restart

# Limit memory usage by docker for stability.
CMD ulimit -n 2048

WORKDIR /

COPY files/phpbrew /usr/local/bin/phpbrew
RUN chmod +x /usr/local/bin/phpbrew
RUN phpbrew init \
 && echo "source /root/.phpbrew/bashrc" >> ~/.bashrc

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
COPY files/behatdrivers/chromedriver /behatdrivers/chromedriver
COPY files/behatdrivers/phantomjs /behatdrivers/phantomjs

RUN phpbrew install ${PHPVERSION} +default +imap=/usr +kerberos +apxs2 +hash +intl +xmlrpc +zlib +exif +ftp +gcov +gd +gettext +iconv +icu +mcrypt +phar +posix +soap +tidy +gmp +mysql +pdo +pgsql +dba -- --with-mssql=/usr/local/freetds --with-pdo-dblib=/usr --with-gd --enable-gd-native-ttf
RUN a2dismod mpm_event && a2enmod mpm_prefork
CMD phpbrew ext install oci8 -- --with-oci8=instantclient,/opt/oracle/instantclient_11_2
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN echo "AddType application/x-httpd-php .php .php5 .phtml" >> /etc/apache2/apache2.conf
RUN echo "DirectoryIndex  index.php  index.html" >> /etc/apache2/apache2.conf

# Increase memory as phpunit might fail otherwise.
RUN sed -i 's/memory_limit = 128M/memory_limit = -1/' /root/.phpbrew/php/php-${PHPVERSION}/etc/php.ini

RUN chmod 775 /scripts/behat.sh \
 && chmod 775 /scripts/phpunit.sh \
 && chmod 775 /scripts/docker_init.sh \
 && chmod 775 /scripts/init.sh \
 && ln -s /behatdrivers/phantomjs /bin/phantomjs
RUN /etc/init.d/postgresql start \
 && /scripts/docker_init.sh

# Create volumes to share faildump.
VOLUME ["/shared"]

# Expose port on which web server is accessible.
EXPOSE 80
