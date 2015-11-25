#!/bin/bash
# This script is for docker input to customise and run behat.
# Exit on errors.
#set -e

# Following params are needed, don't change
RUNNING_TEST='phpunit'

# Dependencies.
. /scripts/lib.sh

################## Functions #####################

# Usage o/p
function usage(){
cat << EOF
################################ Usage #######################################
#                                                                            #
#                             Run Phpunit                                    #
#                                                                            #
##############################################################################
# docker run --rm -v /shared:/shared rajeshtaneja/moodle /scripts/phpunit.sh #
#   --git : git Repository (Default is moodle integration)                   #
#   --remote: git remote (Default is integration)                            #
#   --branch : Branch to use (Default is master)                             #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                  #
#   --phpunitdbprefix : phpunit database perfix (default p_)                 #
#   --filter/test : Filter to use or test file to execute                    #
#   --stoponfail: Stop on fail                                               #
#                                                                            #
##############################################################################
EOF
    exit 0
}

# Create directories if not present.
function create_dirs(){
    mkdir -p $MOODLE_PHPUNIT_DATA_DIR
    chmod 777 $MOODLE_PHPUNIT_DATA_DIR

    mkdir -p $MOODLE_DATA_DIR
    chmod 777 $MOODLE_DATA_DIR
}

# echo build details
function echo_build_details() {
    echo "###########################################"
    echo "## Phpunit build with:"
    echo "## Git Repository: ${GITREPOSITORY}"
    echo "## Git Branch: ${GITBRANCH}"
    echo "## DB Host: ${DBHOST}"
    echo "## DB TYPE: ${DBTYPE}"
    if [[ -n ${PHPUNIT_FILTER} ]]; then
        echo "## filter: ${PHPUNIT_FILTER}"
    fi
    if [[ -n ${PHPUNIT_TEST} ]]; then
        echo "## Test: ${PHPUNIT_TEST}"
    fi
    echo "## IP: $(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')"
    echo "###########################################"
}

#Setup behat.
function setup_phpunit(){
    echo "Installing phpunit for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR

    if [ ! -f "$moodledir/$SiteId/composer.phar" ]; then
        curl -s https://getcomposer.org/installer | php
    fi

    php composer.phar install --prefer-source

    set_mssql

    php admin/tool/phpunit/cli/util.php --drop
    php admin/tool/phpunit/cli/init.php
    cd ${whereami}
}

# Run behat
function run_phpunit(){
    echo "Running behat for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR
    CMD="vendor/bin/phpunit $PHPUNIT_FILTER $PHPUNIT_TEST $STOP_ON_FAIL"
    eval $CMD
    exitcode=${PIPESTATUS[0]}
    exit $exitcode
}
######################################################

# Get user options.
get_user_options "$@"

# Check if required params are set.
check_required_params

# Checkout git branch.
checkout_git_branch

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details

# Setup phpunit.
setup_phpunit

# RUn phpunit.
run_phpunit