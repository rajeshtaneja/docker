#!/bin/bash
# This script is for docker input to customise and run behat.

# Exit on errors.
#set -e

# Shared directory to use.
if [ ! -d "/shared" ]; then
  SHARED_DIR=/root
else
  SHARED_DIR=/shared
fi

# Dependencies.
. /scripts/lib.sh

################## Functions #####################

# Usage o/p
function usage() {
cat << EOF
################################### Usage ##########################################
#                                                                                  #
#                          Install moodle instance                                 #
#                                                                                  #
####################################################################################
# docker run --rm -v /shared:/shared rajeshtaneja/moodle /scripts/init.sh          #
#   --git : git Repository (Default is moodle integration)                         #
#   --remote: git remote (Default is integration)                                  #
#   --branch : Branch to use (Default is master)                                   #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                        #
#   -h : Help                                                                      #
#                                                                                  #
####################################################################################
EOF
    exit 0
}

# Check if required params are set
function check_required_params() {
  # DBHOST should be set.
  if [[ ${DBHOST} = 'localhost' ]]; then
    echo "Local database (postgres) is used for testing..."
    /etc/init.d/postgresql restart
    DBHOST=localhost
  fi
  # Check if git and other commands work.
  check_cmds
}

# Checkout proper git branch
function checkout_git_branch() {
   whereami="${PWD}"
   cd $MOODLE_DIR
   checkout_branch $GITREPOSITORY $GITREMOTE $GITBRANCH
   cd ${whereami}
}

# Start selenium and apache.
function start_apache() {
  # Restart apache server to ensure it is running.
  /etc/init.d/apache2 restart
}

# Create directories if not present.
function create_dirs() {
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
    echo "## IP: $(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')"
    echo "###########################################"
}

# Install moodle
function install_moodle() {
  echo "Installing Moodle for ${DBTYPE} database"
  whereami="${PWD}"
  cd $MOODLE_DIR

  set_mssql

  php admin/cli/install_database.php --adminpass=moodle --adminemail=moodle@example.com --fullname="Moodle Test Site (${DBTYPE})" --shortname="MoodleTestSite-${DBTYPE}" --agree-license

  cd ${whereami}
}

######################################################

# get user options.
OPTS=`getopt -o j::r::p::t::f::n::h --long git::,remote::,branch::,dbhost::,dbtype::,dbname::,dbuser::,dbpass::,dbprefix::,dbport::,profile::,behatdbprefix::,seleniumurl::,phantomjsurl::,process::,processes::,tags::,feature::,name::,help,stoponfail -- "$@"`
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
        --git)
            case "$2" in
                "") GITREPOSITORY=${GITREPOSITORY} ; shift 2 ;;
                *) GITREPOSITORY=$2 ; shift 2 ;;
            esac ;;
        --branch)
            case "$2" in
                "") GITBRANCH=${GITBRANCH} ; shift 2 ;;
                *) GITBRANCH=$2 ; shift 2 ;;
            esac ;;
        --remote)
            case "$2" in
                "") GITREMOTE=${GITREMOTE} ; shift 2 ;;
                *) GITREMOTE=$2 ; shift 2 ;;
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
        --) shift; break;;
        *) echo "Check options" ; usage ; exit 1 ;;
    esac
done

check_required_params
checkout_git_branch
start_apache
set_moodle_config
echo_build_details
install_moodle
# Keep service running.
bash