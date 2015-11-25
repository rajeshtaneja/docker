#!/bin/bash
#
# Common functions.

SCRIPTS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../config
PERMISSIONS=775
DOCKERIP=$(ip addr | grep global | awk '{print substr($2,1,length($2)-3)}')
PHPVERSION=$(php -v | grep cli | awk '{print $1" " substr($2,1,6)}')

## Default params releated to docker container.
HOMEDIR=/
WWWDIR=/var/www/html
MOODLE_DIR_ORG=/moodle
MOODLE_DIR=/var/www/html/moodle
BEHAT_CONFIG_FILE=${HOMEDIR}config/config.php.template
SHARED_DIR=/shared

SCRIPT_LIB_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -f "${SCRIPT_LIB_PATH}/runlib.sh" ]; then
    . ${SCRIPT_LIB_PATH}/runlib.sh
else
    . /scripts/runlib.sh
fi

#if [ ! -d "$MOODLE_DIR" ]; then
#    sudo mkdir -p $MOODLE_DIR
#    sudo chmod 777 $MOODLE_DIR
#    sudo mount -t aufs -o br=${MOODLE_DIR}=rw:${MOODLE_DIR_ORG}=ro none ${MOODLE_DIR}
#fi

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
        BEHAT_PROFILE=firefox
    fi
    if [[ -z ${BEHAT_RUN} ]]; then
        BEHAT_RUN="0" # Process number
    fi
    if [[ -z ${BEHAT_TOTAL_RUNS} ]]; then
        BEHAT_TOTAL_RUNS="1" # Total number of processes
    fi
    if [[ -z ${SELENIUM_URL} ]]; then
        if [[ -n ${SELENIUM_DOCKER_PORT_4444_TCP_ADDR} ]]; then
            SELENIUM_URL=${SELENIUM_DOCKER_PORT_4444_TCP_ADDR}:4444
        fi
    fi
    if [[ -z ${PHANTOMJS_URL} ]]; then
        if [[ -n ${PHANTOMJS_DOCKER_PORT_4444_TCP_ADDR} ]]; then
            PHANTOMJS_URL=${PHANTOMJS_DOCKER_PORT_4444_TCP_ADDR}:4443
        fi
    fi
    if [[ -z ${SHARED_DIR} ]]; then
        SHARED_DIR=/shared

    fi
}

################################################
# Setup mssql
################################################
function set_db() {
    if [ "${DBTYPE}" == "mssql" ]; then
        sudo sed -i "s/host = .*/host = ${DBHOST}/g" /etc/freetds/freetds.conf
    fi

    if [ "${DBTYPE}" == "mysql" ]; then
        DBTYPE=mysqli
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

# Check if required params are set
function check_required_params() {
    # Moodle dir should be mapped.
    if [ ! -d "$MOODLE_DIR" ] && [ ! -d "$MOODLE_DIR_ORG" ]; then
        echo "Moodle dir is not found at $MOODLE_DIR or $MOODLE_DIR_ORG"
        usage 1
    fi

    # DBHOST should be set.
    if [[ -n ${DB_PORT_5432_TCP_ADDR} ]]; then
        DBHOST=$DB_PORT_5432_TCP_ADDR
        DBNAME=$DB_ENV_POSTGRES_USER
        DBUSER=$DB_ENV_POSTGRES_USER
        DBPASS=$DB_ENV_POSTGRES_PASSWORD
    elif [[ -n ${DB_PORT_3306_TCP_ADDR} ]]; then
        DBHOST=$DB_PORT_3306_TCP_ADDR
        DBNAME=$DB_ENV_MYSQL_DATABASE
        DBUSER=$DB_ENV_MYSQL_USER
        DBPASS=$DB_ENV_MYSQL_PASSWORD
    elif [[ -z "$DBHOST" ]]; then
        echo "DBHOST is not set."
        usage 1
    fi

    # Ensure selenium or phantomjs url are there.
    if [ "$TEST_TO_EXECUTE" == "behat" ]; then
        if [ "$BEHAT_PROFILE" == "phantomjs" ] && [ -z "$PHANTOMJS_URL" ]; then
            echo "Phantomjs server is not found"
            usage 1
        elif [ -z "$SELENIUM_URL" ]; then
            echo "Selenium server is not found"
            usage 1
        fi
    fi

    # Check if git and other commands work.
    check_cmds
}

# This is first thing after getting user input to set moodle directory in docker instance and get git repo.
set_moodle_dir_and_branch() {
    # Unfortunately aufs/overlayfs doesn't work well in docker. So use copy.
    if [ ! -d "$MOODLE_DIR" ]; then
        if [ "$(ls -A $MOODLE_DIR_ORG)" ]; then
           sudo chmod 777 $WWWDIR
           cp -r ${MOODLE_DIR_ORG} ${MOODLE_DIR}
           sudo chmod 777 $MOODLE_DIR
        else
            echo "Moodle directory is not mapped to container at /moodle or /var/www/html/moodle"
            exit 1
        fi
    fi

    if [[ -z "$GITBRANCH" ]]; then
        whereami="${PWD}"
        cd $MOODLE_DIR
        LOCAL_BRANCH=`git name-rev --name-only HEAD | sed 's/.*\///g'`
        GIT_CURRENT_BRANCH=$LOCAL_BRANCH
        cd $whereami
        # Load final variables.
        RERUN_FILE="$HOMEDIR${GIT_CURRENT_BRANCH}-rerunlist"
        # Directories shared with host for saving faildump and timing.
        MOODLE_DUMP_DIR=${SHARED_DIR}/${GIT_CURRENT_BRANCH}/${BEHAT_PROFILE}
        MOODLE_FAIL_DUMP_DIR=${SHARED_DIR}/${GIT_CURRENT_BRANCH}/${BEHAT_PROFILE}/run_${BEHAT_RUN}
        BEHAT_TIMING_FILE=${MOODLE_DUMP_DIR}/timing.json
    else
        # Load final variables.
        RERUN_FILE="$HOMEDIR${GITBRANCH}-rerunlist"
        # Directories shared with host for saving faildump and timing.
        MOODLE_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}
        MOODLE_FAIL_DUMP_DIR=${SHARED_DIR}/${GITBRANCH}/${BEHAT_PROFILE}/run_${BEHAT_RUN}
        BEHAT_TIMING_FILE=${MOODLE_DUMP_DIR}/timing.json
    fi
}

# Checkout proper git branch
function checkout_git_branch() {
    whereami="${PWD}"

    # set proper moodle directory and git.
    set_moodle_dir_and_branch

    cd $MOODLE_DIR
    skip=0

    # Get current branch details.
    LOCAL_BRANCH=`git name-rev --name-only HEAD`
    if [ "$LOCAL_BRANCH" = "master" ]; then
        TRACKING_REMOTE="origin"
    else
        TRACKING_REMOTE=`git config branch.$LOCAL_BRANCH.remote`
    fi
    if [ -z "$TRACKING_REMOTE" ]; then
        TRACKING_REMOTE='origin'
        REMOTE_URL=`git config remote.origin.url`
    else
        REMOTE_URL=`git config remote.$TRACKING_REMOTE.url`
    fi

    # If no repository defined then don't checkout.
    if [[ -z "$GITREPOSITORY" ]]; then
        GITREPOSITORY=$REMOTE_URL
        skip=$((skip+1))
    fi
    if [[ -z "$GITBRANCH" ]]; then
        GITBRANCH=`git name-rev --name-only HEAD | sed 's/.*\///g'`
        skip=$((skip+1))
    fi

    if [[ -z "$GITREMOTE" ]]; then
        GITREMOTE=$TRACKING_REMOTE
        skip=$((skip+1))
    fi

    # If no repo/branch/remote given then skip checkout.
    if [ "$skip" -eq 3 ]; then
        cd ${whereami}
        return 0
    fi

    checkout_branch $GITREPOSITORY $GITREMOTE $GITBRANCH
    cd ${whereami}
}

# Start selenium and apache.
function start_apache() {
  # Restart apache server to ensure it is running.
  sudo /etc/init.d/apache2 restart
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
                throw_error "$1 remote value you provide can not be removed."
            git remote add $2 $1 || \
                throw_error "$1 remote value you provided can not be added as $2."
        fi
    # Add it if it is not there.
    else
        git remote add $2 $1 || \
            throw_error "$1 remote can not be added as $2."
    fi

    # Fetching from the repo.
    git fetch $2 --quiet || \
        throw_error "$2 remote can not be fetched. Check $1 is valid"

    # Checking if it is a branch or a hash.
    local isareference="$( git show-ref | grep "refs/remotes/$2/$3$" | wc -l )"
    if [ "$isareference" == "1" ]; then

        # Checkout the last version of the branch.
        # Reset to avoid conflicts if there are git history changes.
        git checkout -B $3 $2/$3 --quiet || \
            throw_error "The '$3' tag or branch you provided does not exist or it is not set."

    else
        # Just checkout the hash and let if fail if it is incorrect.
        git checkout $3 --quiet || \
            throw_error "The '$3' hash you provided does not exist or it is not set."

    fi
}

################################################
# Set config file
#
################################################
function set_moodle_config() {
    if [[ "${DBTYPE}" == "oci" ]]; then
        if [[ -z ${PHPUNIT_DB_PREFIX} ]]; then
            echo "Using xe database for oracle"
            DBNAME=xe
            PHPUNIT_DB_PREFIX="p${str: -1}"
            BEHAT_DB_PREFIX="b${str: -1}"
        fi
    fi

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
  # remove_vendordir
}

function remove_vendordir() {
    if [[ -d $MOODLE_DIR"/vendor" ]]; then
        rm -r $MOODLE_DIR"/vendor"
    fi
}

function create_course_and_users() {
    # If files are present then we have already executed this. don't continue.
    if [ -n "$NO_COURSE" ]; then
        return 0
    fi

    local whereami="${PWD}"
    cd $MOODLE_DIR
    cp /opt/enrol.php $MOODLE_DIR/
    cp /opt/restore.php $MOODLE_DIR/
    cp /opt/users.php $MOODLE_DIR/

    log "Creating course..."
    php restore.php "/opt/AllFeaturesBackup.mbz" > /dev/null 2>&1

    log "Creating users..."
    php users.php > /dev/null 2>&1

    log "Enrolling users..."
    php enrol.php > /dev/null 2>&1
    cd $whereami
}

set_default_variables
