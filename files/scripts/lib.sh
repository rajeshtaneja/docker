#!/bin/bash
#
# Common functions.

SCRIPTS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../config
PERMISSIONS=775


## Default params releated to docker container.
HOMEDIR=/
WWWDIR=/var/www/html
MOODLE_DIR=$WWWDIR/moodle
BEHAT_CONFIG_FILE=${HOMEDIR}config/config.php.template
MOODLE_DATA_DIR=/moodledata/data
MOODLE_PHPUNIT_DATA_DIR=/moodledata/phpunit_data
MOODLE_BEHAT_DATA_DIR=/moodledata/behat_data

RERUN_FILE="${HOMEDIR}$BRANCH-rerunlist"
# Directories shared with host for saving faildump and timing.
MOODLE_FAIL_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}_${BEHAT_PROCESS}
BEHAT_TIMING_FILE=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}_${BEHAT_PROCESS}/timing.json

################################################
# Checks that last command was successfully executed
# otherwise exits showing an error.
#
# Arguments:
#   * $1 => The error message
#
################################################
function throw_error() {
    local errorcode=$?
    if [ "$errorcode" -ne "0" ]; then

        # Print the provided error message.
        if [ ! -z "$1" ]; then
            echo "Error: $1" >&2
        fi

        # Exit using the last command error code.
        exit $errorcode
    fi
}

################################################
# Set default variables if not set
################################################
function set_default_variables() {
    # Git repo to use.
    if [[ -z ${GITREPOSITORY} ]]; then
        GITREPOSITORY=git://git.moodle.org/integration.git
    fi
    if [[ -z ${GITREMOTE} ]]; then
        GITREMOTE=integration
    fi
    if [[ -z ${GITBRANCH} ]]; then
        GITBRANCH=master
    fi
    if [[ -z ${DBHOST} ]]; then
        DBHOST=localhost
    fi
    if [[ -z ${DBTYPE} ]]; then
        DBTYPE=pgsql
    fi
    if [[ -z ${DBNAME} ]]; then
        DBNAME=moodle
    fi
    if [[ -z ${DBUSER} ]]; then
        DBUSER=moodle
    fi
    if [[ -z ${DBPASS} ]]; then
        DBPASS=moodle
    fi
    if [[ -z ${DBPREFIX} ]]; then
        DBPREFIX=mdl_
    fi
    if [[ -z ${DBPORT} ]]; then
        DBPORT=''
    fi
    if [[ -z ${PHPUNIT_DB_PREFIX} ]]; then
        PHPUNIT_DB_PREFIX="p_"
    fi
    if [[ -z ${BEHAT_DB_PREFIX} ]]; then
        BEHAT_DB_PREFIX="b_"
    fi
    if [[ -z ${BEHAT_PROFILE} ]]; then
        BEHAT_PROFILE=default
    fi
    if [[ -z ${BEHAT_PROCESS} ]]; then
        BEHAT_PROCESS="1" # Process number
    fi
    if [[ -z ${BEHAT_PROCESSES} ]]; then
        BEHAT_PROCESSES="1" # Total number of processes
    fi
    if [[ -z ${SELENIUM_URL} ]]; then
        SELENIUM_URL=localhost:4444
    fi
    if [[ -z ${PHANTOMJS_URL} ]]; then
        PHANTOMJS_URL=localhost:4443
    fi
    if [[ -z ${SHARED_DIR} ]]; then
        SHARED_DIR=/shared
    fi
}

################################################
# Setup mssql
################################################
function set_mssql() {
    if [[ "${DBTYPE}" = "mssql" ]]; then
        sed -i "s/host = .*/host = ${DBHOST}/g" /etc/freetds/freetds.conf
    fi
}

################################################
# Deletes the files
#
# Arguments:
#   * $1 => The file/directories to delete
#   * $2 => Set $2 will make the function exit if it is an unexisting file
#
# Accepts dir/*.extension format like ls or rm does.
#
################################################
function delete_files() {
    # Checking that the provided value is not empty or it is a "dangerous" value.
    # We can not prevent anything, just a few of them.
    if [ -z "$1" ] || \
            [ "$1" == "." ] || \
            [ "$1" == ".." ] || \
            [ "$1" == "/" ] || \
            [ "$1" == "./" ] || \
            [ "$1" == "../" ] || \
            [ "$1" == "*" ] || \
            [ "$1" == "./*" ] || \
            [ "$1" == "../*" ]; then
        echo "Error: delete_files() does not accept \"$1\" as something to delete" >&2
        exit 1
    fi

    # Checking that the directory exists. Exiting as it is a development issue.
    if [ ! -z "$2" ]; then
        test -e "$1" || \
            throw_error "The provided \"$1\" file or directory does not exist or is not valid."
    fi

    # Kill them all (ok, yes, we don't always require that options).
    rm -rf $1
}

################################################
# Checks that the provided cmd commands are properly set.
#
################################################
function check_cmds() {
    local readonly genericstr=" has a valid value or overwrite the default one using webserver_config.properties"

    php -v > /dev/null || \
        throw_error 'Ensure $phpcmd'$genericstr

    git version > /dev/null || \
        throw_error 'Ensure $gitcmd'$genericstr

    curl -V > /dev/null || \
        throw_error 'Ensure $curlcmd'$genericstr
}

################################################
# Checks out the specified branch codebase for the specified repository
#
# Arguments:
#   $1 => repo
#   $2 => remote alias
#   $3 => branch
#
################################################
function checkout_branch() {

    # Getting the code.
    if [ ! -e ".git" ]; then
        git init --quiet
    fi

    # Add/update the remote if necessary.
    local remotes="$( git remote show )"
    if [[ "$remotes" == *$2* ]] || [ "$remotes" == "$2" ]; then

        # Remove the remote if it already exists and it is different.
        local remoteinfo="$( git remote show "$2" -n | head -n 3 )"
        if [[ ! "$remoteinfo" == *$1* ]]; then
            git remote rm $2 || \
                throw_error "$1 remote value you provide can not be removed. Check webserver_config.properties.dist"
            git remote add $2 $1 || \
                throw_error "$1 remote value you provided can not be added as $2. Check webserver_config.properties.dist"
        fi
    # Add it if it is not there.
    else
        git remote add $2 $1 || \
            throw_error "$1 remote can not be added as $2. Check webserver_config.properties.dist"
    fi

    # Fetching from the repo.
    git fetch $2 --quiet || \
        throw_error "$2 remote can not be fetched. Check webserver_config.properties.dist"

    # Checking if it is a branch or a hash.
    local isareference="$( git show-ref | grep "refs/remotes/$2/$3$" | wc -l )"
    if [ "$isareference" == "1" ]; then

        # Checkout the last version of the branch.
        # Reset to avoid conflicts if there are git history changes.
        git checkout -B $3 $2/$3 --quiet || \
            throw_error "The '$3' tag or branch you provided does not exist or it is not set. Check webserver_config.properties.dist"

    else
        # Just checkout the hash and let if fail if it is incorrect.
        git checkout $3 --quiet || \
            throw_error "The '$3' hash you provided does not exist or it is not set. Check webserver_config.properties.dist"

    fi
}

################################################
# Set config file
#
################################################
function set_moodle_config() {
    if [[ "${DBTYPE}" == "oci" ]]; then
        echo "Using xe database for oracle"
        DBNAME=xe
        PHPUNIT_DB_PREFIX="p${str: -1}"
        BEHAT_DB_PREFIX="b${str: -1}"
    fi

    DOCKERIP=$(ifconfig eth0 | awk '/inet addr/{print substr($2,6)}')
    # If behat running then set ip to
    if [[ -z ${RUNNING_TEST} ]]; then
        DOCKERIPWEB=$DOCKERIP
        DOCKERIPBEHAT='127.0.0.1'
    elif [[ ${RUNNING_TEST} = 'phpunit' ]]; then
        DOCKERIPWEB=$DOCKERIP
        DOCKERIPBEHAT='127.0.0.1'
    else
        DOCKERIPWEB='127.0.0.1'
        DOCKERIPBEHAT=$DOCKERIP
    fi

  # Copying from config template.
 replacements="%%DbType%%#${DBTYPE}
%%DbHost%%#${DBHOST}
%%DbName%%#${DBNAME}
%%DbUser%%#${DBUSER}
%%DbPwd%%#${DBPASS}
%%SiteDbPrefix%%#${DBPREFIX}
%%DbPort%%#${DBPORT}
%%DataDir%%#${MOODLE_DATA_DIR}
%%PhpUnitDataDir%%#${MOODLE_PHPUNIT_DATA_DIR}
%%PhpunitDbPrefix%%#${PHPUNIT_DB_PREFIX}
%%BehatDataDir%%#${MOODLE_BEHAT_DATA_DIR}
%%BehatDbPrefix%%#${BEHAT_DB_PREFIX}
%%SiteId%%#${BRANCH}
%%FailDumpDir%%#${MOODLE_FAIL_DUMP_DIR}
%%BehatTimingFile%%#${BEHAT_TIMING_FILE}
%%SeleniumUrl%%#${SELENIUM_URL}
%%PhantomjsUrl%%#${PHANTOMJS_URL}
%%DockerContainerIp%%#${DOCKERIPWEB}
%%DockerContainerIpBehat%%#${DOCKERIPBEHAT}"
  # Apply template transformations.
  text="$( cat $BEHAT_CONFIG_FILE )"
  for i in ${replacements}; do
      text=$( echo "${text}" | sed "s#${i}#g" )
  done

  # Save the config.php into destination.
  echo "${text}" > $MOODLE_DIR/config.php
  create_dirs
}

set_default_variables