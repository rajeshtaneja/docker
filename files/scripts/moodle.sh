#!/bin/bash
# This script is for docker input to customise and run behat.

# Exit on errors.
#set -e

# Dependencies.
SCRIPT_LIB_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -f "${SCRIPT_LIB_PATH}/lib.sh" ]; then
    . ${SCRIPT_LIB_PATH}/lib.sh
else
    . /scripts/lib.sh
fi

################## Functions #####################

# Usage o/p
function usage() {
cat << EOF
################################################ Usage ###############################################
#                                                                                                    #
#                                      Install moodle instance                                       #
#                                                                                                    #
######################################################################################################
# docker run --rm -v /MOODLE_ON_HOST:/moodle -v /shared:/shared rajeshtaneja/php:7.0 /moodle_site    #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                                          #
#   --git : (optional) git Repository                                                                #
#   --remote: (optional) git remote                                                                  #
#   --branch : (optional) Branch to use                                                              #
#   -h : Help                                                                                        #
#                                                                                                    #
######################################################################################################
EOF
    exit 0
}

#################################################
# Set enviornment to run moodle
#################################################
function set_moodle_run_env() {
    # Load final variables.
    MOODLE_VERSION=$(grep "\$branch" ${MOODLE_DIR}/version.php | sed "s/';.*//" | sed "s/^\$.*'//")

    # Moodle data dir to create.
    MOODLE_DATA_BASE_DIR=${SHARED_DATA_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}
    MOODLE_DATA_DIR=${MOODLE_DATA_BASE_DIR}/data
    MOODLE_PHPUNIT_DATA_DIR=${MOODLE_DATA_BASE_DIR}/phpunit_data
    MOODLE_BEHAT_DATA_DIR=${MOODLE_DATA_BASE_DIR}/behat_data

    # Create data dir if not present. Create it one by one.
    if [ ! -d "${MOODLE_DATA_BASE_DIR}" ]; then
        sudo mkdir -p ${MOODLE_DATA_BASE_DIR}
        sudo chmod -R 777 ${SHARED_DATA_DIR}
    fi
    if [ ! -d "$MOODLE_DATA_DIR" ]; then
        mkdir $MOODLE_DATA_DIR
        chmod 777 -R $MOODLE_DATA_DIR
    fi
    if [ ! -d "$MOODLE_PHPUNIT_DATA_DIR" ]; then
        mkdir $MOODLE_PHPUNIT_DATA_DIR
        chmod 777 -R $MOODLE_PHPUNIT_DATA_DIR
    fi
    if [ ! -d "$MOODLE_BEHAT_DATA_DIR" ]; then
        mkdir $MOODLE_BEHAT_DATA_DIR
        chmod 777 -R $MOODLE_BEHAT_DATA_DIR
    fi

    # Create behat site data
    if [ -n "$BEHAT_RUN" ] && [ "$BEHAT_RUN" -gt 0 ]; then
        if [ ! -d "$MOODLE_BEHAT_DATA_DIR$BEHAT_RUN" ]; then
            mkdir -m777 $MOODLE_BEHAT_DATA_DIR$BEHAT_RUN
        fi
    fi

    # Behat config file to use.
    if [ "$MOODLE_VERSION" -ge "31" ]; then
        BEHAT_CONFIG_FILE=${HOMEDIR}config/config.php.behat3.template
    fi

    # Rerun file to save to.
    RERUN_FILE="${MOODLE_DATA_BASE_DIR}/${GITBRANCH}-rerunlist"

    # Directories shared with host for saving faildump and timing.
    MOODLE_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}
    MOODLE_FAIL_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}/run
    BEHAT_TIMING_FILE=${MOODLE_DUMP_DIR}/timing.json

    if [ "$MOODLE_VERSION" -ge "31" ]; then
        BEHAT_FORMAT="--format=moodle_progress --out=std"
        BEHAT_OUTPUT="--format=pretty --out=${MOODLE_FAIL_DUMP_DIR}/pretty{runprocess}.txt --replace={runprocess}"
    else
        BEHAT_FORMAT="--format='moodle_progress,pretty,html'"
        BEHAT_OUTPUT="--out=',${MOODLE_FAIL_DUMP_DIR}/pretty{runprocess}.txt,${MOODLE_FAIL_DUMP_DIR}/progress.html' --replace={runprocess}"
    fi

    if [[ ! -d ${MOODLE_DUMP_DIR} ]]; then
        mkdir -p ${MOODLE_DUMP_DIR}
        chmod 777 ${MOODLE_DUMP_DIR}
    fi

    if [[ ! -d ${MOODLE_FAIL_DUMP_DIR} ]]; then
        mkdir -p ${MOODLE_FAIL_DUMP_DIR}
        chmod 777 ${MOODLE_FAIL_DUMP_DIR}
    fi

    if [[ ! -d ${MOODLE_FAIL_DUMP_DIR}/screenshots ]]; then
        mkdir -p ${MOODLE_FAIL_DUMP_DIR}/screenshots
        chmod 777 ${MOODLE_FAIL_DUMP_DIR}/screenshots
    fi
}

# echo build details
function echo_build_details() {
    echo "###########################################"
    echo "#      Moodle on: ${PHPVERSION}            "
    echo "###########################################"
    echo "## Behat build with:"
    echo "## Git Repository: ${GITREPOSITORY}"
    echo "## Git Branch: ${GITBRANCH}"
    echo "## DB Host: ${DBHOST}"
    echo "## DB TYPE: ${DBTYPE}"
    echo "## IP: ${DOCKERIP}"
    echo "###########################################"
}

# Install moodle
function install_moodle() {
    echo "Installing Moodle for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR

    php admin/cli/install_database.php --adminpass=moodle --adminemail=moodle@example.com --fullname="Moodle Test Site (${DBTYPE})" --shortname="MoodleTestSite-${DBTYPE}" --agree-license > /dev/null 2>&1

    cd ${whereami}
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

# Start apache.
start_apache

# Set env for moodle.
set_moodle_run_env

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details

# Install moodle.
install_moodle

# Create course and users.
create_course_and_users

# If passed keep alive then it's interactive mode.
if [[ -z ${KEEPALIVE} ]]; then
    echo "#######################################################################"
    echo "##  You can access moodle via http://${DOCKERIPWEB}/moodle"
    echo "##  Username/password: admin/moodle"
    echo "##  Access container via 'docker exec -ti ${HOSTNAME} bash'"
    echo "##  To stop containet type 'docker stop ${HOSTNAME}'"
    echo "#######################################################################"
    sudo tail -F /var/log/apache2/error.log
else
    bash
fi
