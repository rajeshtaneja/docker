#!/bin/bash

# Dependencies.
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Default params which can be overridden by options.
DEFAULT_SELENIUM_DOCKER="rajeshtaneja/selenium:2.53.0"
DEFAULT_DOCKER_PHP_VERSION="7.0"
DB_DOCKER_TO_START_CMD='docker run -e POSTGRES_USER=moodle -e POSTGRES_PASSWORD=moodle -e POSTGRES_DB=moodle -d postgres'

# Optional parameters if set here then don't need to pass via command line.
# Command line will be given preference.
#DBTYPE='pgsql'
#DBHOST='raji.per.in.moodle.com'
#DBUSER='moodle'
#DBPASS='moodle'
#DBNAME='moodle'
#DBPREFIX='b_'
#DBPORT=3361
#TEST_TO_EXECUTE='behat'
#DOCKER_USE_HOST_CODE=""

####### Behat specific
#BEHAT_RUN=0
#BEHAT_TOTAL_RUNS=4
#BEHAT_PROFILE
#BEHAT_DB_PREFIX
#SELENIUM_URL
#PHANTOMJS_URL
#BEHAT_TAGS
#BEHAT_FEATURE
#BEHAT_NAME

# PHPunit Specific
#PHPUNIT_DB_PREFIX
#PHPUNIT_TEST
#PHPUNIT_FILTER


# Include functions required for run script.
. ${ROOT_DIR}/files/scripts/runlib.sh

trap stop_all_instances HUP INT QUIT TERM EXIT

# Usage o/p
function usage() {
cat << EOF
####################################### Usage ##############################################
#                                                                                          #
#                          Start Moodle docker container                                   #
#                                                                                          #
############################################################################################
# ./run.sh --moodlepath='/PAT/TO/MOODLE/ON/HOST' --execute='phpunit'                       #
#   --execute: Test to execute. phpunit or behat or moodle                                 #
#   --moodlepath: Path to moodle dir on host machine                                       #
#                                                                                          #
# Optional params                                                                          #
#   --shareddir:      Shared directory on host where faildumps/moodledata will be stored.  #
#   --phpversion:     Php version to use. 5.4, 5.5, 5.6, 7.0                               #
#   --phpdocker:      Docker instance you would like to use. default is rajeshtaneja/php   #
#   --seleniumdocker: Docker instance you would like to use.                               #
#   --dbdockercmd:    Full db docker comand to start docker instance.                      #
#   --user:           Default docker has jenkins and moodle user.                          #
#   --usehostcode:    Copy of Moodle code is used by default. If you want to use host copy #
#                  and let config.php be written by docker then use this                   #
#                                                                                          #
# Help if needed.                                                                          #
#   -h|--help :    Run script Help                                                         #
#   --behathelp:   behat specific options                                                  #
#   --phpunithelp: phpunit specific help.                                                  #
#   --verbose:     Verbose o/p of script                                                   #
#   --noninteractive: Use this if running via script.                                      #
#   --noselenium:  Don't attach selenium (when running moodle)                             #
#   --forcedrop:   Drop test site before init. default it will just use init               #
#                                                                                          #
############################################################################################
EOF
    if [ -n "$1" ]; then
        exit $1
    else
        exit 0
    fi
}

# Get user options.
get_user_options "$@"

create_db_instance

create_selenium_instance

update_composer_on_host

start_php_server_and_run_test

EXITCODE=$?

stop_all_instances

log "** Exit from run.sh is: $EXITCODE"
exit $EXITCODE