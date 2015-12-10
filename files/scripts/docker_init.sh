#!/bin/bash
# This script is for docker input to customise and run behat.

# Exit on errors.
set -e

# Dependencies.
. /scripts/lib.sh

PHPVERSION_INT=${PHPVERSION%.*}
PHPVERSION_INT=${PHPVERSION_INT%.*}
# Disable php5 module for apache.
if [[ ${PHPVERSION_INT} = 7 ]]; then
    a2dismod php5
fi
source /root/.phpbrew/bashrc && phpbrew switch php-${PHPVERSION}

whereami="${PWD}"
# Create clone of moodle to ship with.
if [[ ${IGNORECLONE} -eq 0 ]]; then
    git clone $GITREPOSITORY /var/www/html/moodle
    cd /var/www/html/moodle
    checkout_branch $GITREPOSITORY $GITREMOTE $GITBRANCH
    curl -s https://getcomposer.org/installer | php
    php composer.phar install --prefer-source
fi

# Create postgres user and db and stop it.
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'moodle';" \
 && sudo -u postgres createuser --superuser moodle \
 && sudo -u postgres psql -c "ALTER USER moodle WITH PASSWORD 'moodle';" \
 && sudo -u postgres psql -c "CREATE DATABASE moodle WITH OWNER moodle ENCODING 'UTF8' LC_COLLATE='en_AU.utf8' LC_CTYPE='en_AU.utf8' TEMPLATE=template0;" \
 && /etc/init.d/postgresql stop \
 && /etc/init.d/mysql stop \
 && /etc/init.d/apache2 stop

cd ${whereami}
