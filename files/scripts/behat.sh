#!/bin/bash
# This script is for docker input to customise and run behat.

# Exit on errors.
#set -e
RUNNING_TEST='behat'

# Dependencies.
. /scripts/lib.sh

################## Functions #####################

# Usage o/p
function usage() {
cat << EOF
#################################### Usage #########################################
#                                                                                  #
#                                  Run behat                                       #
#                                                                                  #
####################################################################################
# docker run --rm -v /shared:/shared rajeshtaneja/moodle /scripts/behat.sh -r1 -j2 #
#   --git : git Repository (Default is moodle integration)                         #
#   --remote: git remote (Default is integration)                                  #
#   --branch : Branch to use (Default is master)                                   #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                        #
#   --behatdbprefix: Behat db prefix (default is b_)                               #
#   --profile/tags/feature/name : Behat specific options                           #
#   --process/processes : Process to run out of how many processes                 #
#   --stoponfail: Stop on fail                                                     #
#   -h : Help                                                                      #
#                                                                                  #
####################################################################################
EOF
    exit 0
}

# Start selenium and apache.
function start_apache_selenium() {
    start_apache

    # Start local selenium if needed.
    if [[ ${SELENIUM_URL} = 'localhost:4444' ]]; then
        echo "Starting SeleniumServer at port: 4444"
        xvfb-run -a java -jar ${HOMEDIR}behatdrivers/selenium-server-2.47.1.jar -port 4444 -Dwebdriver.chrome.driver=${HOMEDIR}behatdrivers/chromedriver > /dev/null 2>&1 &
        sleep 5
    fi

    # Start local phantomjs instance if needed.
    if [[ ${BEHAT_PROFILE} = 'phantomjs' ]]; then
        if [[ ${PHANTOMJS_URL} = 'localhost:4443' ]]; then
            echo "Starting PHANTOMJS at port: 4443"
            ${HOMEDIR}behatdrivers/phantomjs --webdriver 4443 > /dev/null 2>&1 &
            sleep 5
        fi
    fi
}

# Create directories if not present.
function create_dirs() {
    mkdir -p $MOODLE_BEHAT_DATA_DIR
    chmod 777 $MOODLE_BEHAT_DATA_DIR

    # Create behat site data
    if [[ ! -d "$MOODLE_BEHAT_DATA_DIR$BEHAT_PROCESS" ]]; then
        mkdir -m777 $MOODLE_BEHAT_DATA_DIR$BEHAT_PROCESS;
    fi

    mkdir -p $MOODLE_PHPUNIT_DATA_DIR
    chmod 777 $MOODLE_PHPUNIT_DATA_DIR

    # Create screenshot directory if not present.scratch
    mkdir -p $MOODLE_FAIL_DUMP_DIR/$BRANCH
    chmod 777 $MOODLE_FAIL_DUMP_DIR/$BRANCH

    if [[ ! -d "$MOODLE_DATA_DIR" ]]; then
        mkdir -m777 $MOODLE_DATA_DIR;
    fi
}

# echo build details
function echo_build_details() {
    echo "###########################################"
    echo "## Behat build with:"
    echo "## Git Repository: ${GITREPOSITORY}"
    echo "## Git Branch: ${GITBRANCH}"
    echo "## DB Host: ${DBHOST}"
    echo "## DB TYPE: ${DBTYPE}"
    echo "## PROCESS: ${BEHAT_PROCESS}/${BEHAT_PROCESSES}"
    echo "## Faildump: ${MOODLE_FAIL_DUMP_DIR}"
    if [[ -n ${BEHAT_PROFILE} ]]; then
        echo "## Behat profile: ${BEHAT_PROFILE}"
    fi
    if [[ -n ${BEHAT_TAGS} ]]; then
        echo "## Behat tags: ${BEHAT_TAGS}"
    fi
    if [[ -n ${BEHAT_NAME} ]]; then
        echo "## Behat feature/scenario name: ${BEHAT_NAME}"
    fi
    if [[ -n ${BEHAT_FEATURE} ]]; then
        echo "## Behat feature: ${BEHAT_FEATURE}"
    fi
    echo "## IP: $(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')"
    echo "###########################################"
}

#Setup behat.
function setup_behat() {
  echo "Installing behat for ${DBTYPE} database"
  whereami="${PWD}"
  cd $MOODLE_DIR

  if [ ! -f "$MOODLE_DIR/composer.phar" ]; then
    curl -s https://getcomposer.org/installer | php
  fi

  set_mssql

  php composer.phar install --prefer-source

  php admin/tool/behat/cli/util.php --drop
  if [[ $BEHAT_PROCESS = "" ]]; then
    php admin/tool/behat/cli/init.php
  else
    php admin/tool/behat/cli/init.php -j=$BEHAT_PROCESSES --fromrun=$BEHAT_PROCESS --torun=$BEHAT_PROCESS
  fi
  cd ${whereami}
}

# Run behat
function run_behat() {
    echo "Running behat for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR
    if [[ $BEHAT_PROCESS = "" ]]; then
        BEHAT_PROCESSES=1
        CMD="php admin/tool/behat/cli/run.php --rerun=\"$RERUN_FILE$BEHAT_PROCESSES.txt\" $BEHAT_FORMAT $BEHAT_OUTPUT -p=$BEHAT_PROFILE $BEHAT_TAGS $STOP_ON_FAIL $BEHAT_NAME $BEHAT_FEATURE"
    else
        CMD="php admin/tool/behat/cli/run.php --rerun=\"$RERUN_FILE{runprocess}.txt\" $BEHAT_FORMAT $BEHAT_OUTPUT --replace=\"{runprocess}\" --fromrun=$BEHAT_PROCESS --torun=$BEHAT_PROCESS -p=$BEHAT_PROFILE $BEHAT_TAGS $STOP_ON_FAIL $BEHAT_NAME $BEHAT_FEATURE"
    fi
    eval $CMD
    exitcode=${PIPESTATUS[0]}

    if [[ -n ${STOP_ON_FAIL} ]]; then
        exit $exitcode
    fi

    # Re-run failed scenarios, to ensure they are true fails.
    if [ "${exitcode}" -ne 0 ]; then
        exitcode=0
        for ((i=1;i<=$BEHAT_PROCESSES;i+=1)); do
            thisrerunfile="$RERUN_FILE$i.txt"
            if [ -e "${thisrerunfile}" ]; then
                if [ -s "${thisrerunfile}" ]; then
                        echo "---Running behat again for failed steps---"
                        if [ ! -L $MOODLE_DIR/behatrun$i ]; then
                            ln -s $MOODLE_DIR $MOODLE_DIR/behatrun$i
                        fi
                        sleep 5
                        CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR$i/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT --verbose --rerun $thisrerunfile -p=$BEHAT_PROFILE $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE"
                        eval $CMD
                        exitcode=$(($exitcode+${PIPESTATUS[0]}))
                fi
                rm $thisrerunfile
            fi
        done;
    fi

  exit $exitcode

}
######################################################

# Get user options.
get_user_options "$@"

# Load final variables.
RERUN_FILE="$HOMEDIR${GITBRANCH}-rerunlist"
# Directories shared with host for saving faildump and timing.
MOODLE_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}
MOODLE_FAIL_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}/run_${BEHAT_PROCESS}
BEHAT_TIMING_FILE=${MOODLE_DUMP_DIR}/timing.json
BEHAT_FORMAT="--format='moodle_progress,pretty,html'"
BEHAT_OUTPUT="--out=',${MOODLE_FAIL_DUMP_DIR}/pretty.txt,${MOODLE_FAIL_DUMP_DIR}/progress.html'"

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


# Check if required params are set.
check_required_params

# Checkout git branch.
checkout_git_branch

# Start apache.
start_apache_selenium

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details

# Setup behat.
setup_behat

# Run behat.
run_behat