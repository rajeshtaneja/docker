#!/bin/bash

# Dependencies.
SCRIPT_LIB_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -f "${SCRIPT_LIB_PATH}/lib.sh" ]; then
    . ${SCRIPT_LIB_PATH}/lib.sh
else
    SCRIPT_LIB_PATH=/scripts
    . /scripts/lib.sh
fi

# Usage o/p
function usage() {
cat << EOF
####################################### Usage ##############################################
#                                                                                          #
#                               Moodle docker container                                    #
#                                                                                          #
############################################################################################
# docker run -ti --moodlepath='/PAT/TO/MOODLE/ON/HOST' rajeshtaneja/php:7.0                #
#   --execute: Test to execute. phpunit or behat or moodle                                 #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                                #
#   --git : (OPTIONAL) git Repository                                                      #
#   --remote: (OPTIONAL) git remote                                                        #
#   --branch : (OPTIONAL) Branch to use                                                    #
#                                                                                          #
# Help if needed.                                                                          #
#   -h|--help :    Run script Help                                                         #
#   --behathelp:   behat specific options                                                  #
#   --phpunithelp: phpunit specific help.                                                  #
############################################################################################
EOF
    if [ -n "$1" ]; then
        exit $1
    else
        exit 0
    fi
}

if [ -z "$1" ] || [ "$1" == "" ]; then
    usage 1
else

    # Get user options.
    get_user_options "$@"
    if [ "$TEST_TO_EXECUTE" == "behat" ]; then
        /scripts/behat.sh "$@"
    elif [ "$TEST_TO_EXECUTE" == "phpunit" ]; then
        /scripts/phpunit.sh "$@"
    elif [ "$TEST_TO_EXECUTE" == "moodle" ]; then
        /scripts/moodle.sh "$@"
    else
        usage 1
    fi
    EXITCODE=$?
fi

exit $EXITCODE