#!/bin/bash
# This script is for docker input to customise and run behat.
# Exit on errors.
#set -e

# Following params are needed, don't change
RUNNING_TEST='phpunit'

# Dependencies.
SCRIPT_LIB_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -f "${SCRIPT_LIB_PATH}/lib.sh" ]; then
    . ${SCRIPT_LIB_PATH}/lib.sh
else
    . /scripts/lib.sh
fi

################## Functions #####################

# Usage o/p
function usage(){
cat << EOF
######################################## Usage ###############################################
#                                                                                            #
#                                      Run Phpunit                                           #
#                                                                                            #
##############################################################################################
# docker run --rm --user=moodle -v /MOODLE_PATH:/moodle rajeshtaneja/php:5.4.45 /phpunit     #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                                  #
#   --phpunitdbprefix (optional): phpunit database perfix (default p_)                       #
#   --filter/test (optional): Filter to use or test file to execute                          #
#   --stoponfail; (optional) Stop on fail                                                    #
#   --git : (Optional) git Repository                                                        #
#   --remote : (Optional) git remote (Default is integration)                                #
#   --branch : (Optional) Branch to use (Default is master)                                  #
#                                                                                            #
##############################################################################################
EOF
    exit 0
}

#################################################
# Set enviornment to run phpunit
#################################################
function set_phpunit_run_env() {
    # Load final variables.
    MOODLE_VERSION=$(grep "\$branch" ${MOODLE_DIR}/version.php | sed "s/';.*//" | sed "s/^\$.*'//")

    # Moodle data dir to create.
    MOODLE_DATA_BASE_DIR=${SHARED_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}
    MOODLE_DATA_DIR=${MOODLE_DATA_BASE_DIR}/data
    MOODLE_PHPUNIT_DATA_DIR=${MOODLE_DATA_BASE_DIR}/phpunit_data
    MOODLE_BEHAT_DATA_DIR=${MOODLE_DATA_BASE_DIR}/behat_data

    # Create data dir if not present. Create it one by one.
    if [ ! -d "${SHARED_DIR}" ]; then
        sudo mkdir -p ${SHARED_DIR}
        sudo chmod 777 ${SHARED_DIR}
    fi

    # Create data dir if not present. Create it one by one.
    if [ ! -d "${SHARED_DIR}/moodledata" ]; then
        sudo mkdir ${SHARED_DIR}/moodledata
        sudo chmod 777 ${SHARED_DIR}/moodledata
    fi
    if [ ! -d "${SHARED_DIR}/moodledata/${MOODLE_VERSION}" ]; then
        mkdir ${SHARED_DIR}/moodledata/${MOODLE_VERSION}
        chmod 777 ${SHARED_DIR}/moodledata/${MOODLE_VERSION}
    fi
    if [ ! -d "${SHARED_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}" ]; then
        mkdir ${SHARED_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}
        chmod 777 -R ${SHARED_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}
    fi
    if [ ! -d "$MOODLE_DATA_DIR" ]; then
        mkdir $MOODLE_DATA_DIR
        chmod 777 -R $MOODLE_DATA_DIR
    fi
    if [ ! -d "$MOODLE_PHPUNIT_DATA_DIR" ]; then
        mkdir $MOODLE_PHPUNIT_DATA_DIR
        chmod 777 -R $MOODLE_PHPUNIT_DATA_DIR
    fi

    # Behat config file to use.
    if [ "$MOODLE_VERSION" -ge "31" ]; then
        BEHAT_CONFIG_FILE=${HOMEDIR}config/config.php.behat3.template
    fi
}

# echo build details
function echo_build_details() {
    echo "###########################################"
    echo "#       Phpunit on: ${PHPVERSION}         "
    echo "###########################################"
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
    echo "## $1"
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

    php composer.phar install --prefer-dist --no-interaction

    # No need to drop site, init will do the job if needed.
    if [ -n "$DROP_SITE" ]; then
        php admin/tool/phpunit/cli/util.php --drop
    fi

    php admin/tool/phpunit/cli/init.php
    cd ${whereami}
}

# Run behat
function run_phpunit(){
    echo "Running behat for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR
    CMD="vendor/bin/phpunit $PHPUNIT_FILTER $PHPUNIT_TEST $STOP_ON_FAIL"
    log "$CMD"
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

# Set db changes if needbe.
set_db

# Set env for phpunit.
set_phpunit_run_env

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details "Setup phpunit..."

# Setup phpunit.
setup_phpunit

# If only setup is set then don't run phpunit.
if [ -z "$ONLY_SETUP" ]; then
    # Show user details about build.
    echo_build_details "Running phpunit..."

    # Run phpunit.
    run_phpunit
fi