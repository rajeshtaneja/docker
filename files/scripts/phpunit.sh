#!/bin/bash
# This script is for docker input to customise and run behat.
# Exit on errors.
#set -e

# Following params are needed, don't change
SHARED_DIR=/root
if [ ! -d "/shared" ]; then
  SHARED_DIR=/root
else
  SHARED_DIR=/shared
fi

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

# Check if required params are set
function check_required_params(){
    # DBHOST should be set.
    if [[ ${DBHOST} = "localhost" ]]; then
        echo "Local database (postgres) is used for testing..."
        /etc/init.d/postgresql restart
        DBHOST=localhost
    fi
    # Check if git and other commands work.
    check_cmds
}
# Checkout proper git branch
function checkout_git_branch(){
    whereami="${PWD}"
    cd $MOODLE_DIR
    checkout_branch $GITREPOSITORY $GITREMOTE $GITBRANCH
    cd ${whereami}
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
OPTS=`getopt -o t::f::h --long git::,branch::,dbhost::,dbtype::,dbname::,dbuser::,dbpass::,dbprefix::,dbport::,phpunitdbprefix::,filter::,test::,help,stoponfail -- "$@"`
if [ $? != 0 ]
then
    echo "Give proper option"
    usage
    exit 1
fi

eval set -- "$OPTS"

while true ; do
    case "$1" in
        -h|--help) usage; shift ;;
        --stoponfail) STOP_ON_FAIL='--stop-on-failure'; shift ;;
        --git)
            case "$2" in
                "") GITREPOSITORY=${GITREPOSITORY} ; shift 2 ;;
                *) GITREPOSITORY=$2 ; shift 2 ;;
            esac ;;
        --remote)
            case "$2" in
                "") GITREMOTE=${GITREMOTE} ; shift 2 ;;
                *) GITREMOTE=$2 ; shift 2 ;;
            esac ;;
        --branch)
            case "$2" in
                "") GITBRANCH=${GITBRANCH} ; shift 2 ;;
                *) GITBRANCH=$2 ; shift 2 ;;
            esac ;;
        --dbhost)
            case "$2" in
                "") DBHOST=${DBHOST} ; shift 2 ;;
                *) DBHOST=$2 ; shift 2 ;;
            esac ;;
        --dbtype)
            case "$2" in
                "") DBTYPE=${DBTYPE} ; shift 2 ;;
                *) DBTYPE=$2 ; shift 2 ;;
            esac ;;
        --dbname)
            case "$2" in
                "") DBNAME=${DBNAME} ; shift 2 ;;
                *) DBNAME=$2 ; shift 2 ;;
            esac ;;
        --dbuser)
            case "$2" in
                "") DBUSER=${DBUSER} ; shift 2 ;;
                *) DBUSER=$2 ; shift 2 ;;
            esac ;;
        --dbpass)
            case "$2" in
                "") DBPASS=${DBPASS} ; shift 2 ;;
                *) DBPASS=$2 ; shift 2 ;;
            esac ;;
        --dbprefix)
            case "$2" in
                "") DBPREFIX=${DBPREFIX} ; shift 2 ;;
                *) DBPREFIX=$2 ; shift 2 ;;
            esac ;;
        --dbport)
            case "$2" in
                "") DBPORT=${DBPORT} ; shift 2 ;;
                *) DBPORT=$2 ; shift 2 ;;
            esac ;;
        --phpunitdbprefix)
            case "$2" in
                "") PHPUNIT_DB_PREFIX=${PHPUNIT_DB_PREFIX} ; shift 2 ;;
                *) PHPUNIT_DB_PREFIX=$2 ; shift 2 ;;
            esac ;;
        -t|--test)
            case "$2" in
                "") PHPUNIT_TEST="" ; shift 2 ;;
                *) PHPUNIT_TEST=" \"$2\"" ; shift 2 ;;
            esac ;;
        -f|--filter)
            case "$2" in
                "") PHPUNIT_FILTER=${BEHAT_FEATURE} ; shift 2 ;;
                *) PHPUNIT_FILTER="--filter=\"$2\"" ; shift 2 ;;
            esac ;;
        --) shift; break;;
        *) echo "Check options...." ; usage; exit 1 ;;
    esac
done

check_required_params
checkout_git_branch
set_moodle_config
echo_build_details
setup_phpunit
run_phpunit