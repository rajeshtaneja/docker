#!/bin/bash
############ Specific functions for running whole test #############
# Default php version is 7.0 if not found.

function get_user_options() {
    # get user options.
    local currentdir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

    ORGINIAL_USER_OPTS="$@"
    OPTS=`getopt -o j::r::p::t::f::n::h --long git::,remote::,branch::,dbhost::,dbtype::,dbname::,dbuser::,dbpass::,dbprefix::,dbport::,profile::,behatdbprefix::,seleniumurl::,run::,totalruns::,tags::,feature::,suite::,name::,phpunitdbprefix::,filter::,test::,execute::,moodlepath::,phpversion::,phpdocker::,seleniumdocker::,dbdockercmd::,shareddir::,shareddatadir::,user::,behathelp,phpunithelp,usehostcode,verbose,noninteractive,noselenium,help,stoponfail,onlysetup,nocourse,forcedrop,logjunit -- $ORGINIAL_USER_OPTS`

    if [ $? != 0 ]
    then
        echo "Give proper option"
        usage
        exit 1
    fi

    eval set -- "$OPTS"

    while true ; do
        case "$1" in
            -h|--help)
                if [ -z "$RUNNING_TEST" ]; then
                    usage
                else
                    ${currentdir}/${RUNNING_TEST}.sh --help
                fi
                shift ;;
            --behathelp) ${currentdir}/behat.sh --help; shift ;;
            --phpunithelp) ${currentdir}/phpunit.sh --help; shift ;;
            --usehostcode) DOCKER_MOODLE_PATH=1; shift ;;
            --verbose) SHOW_VERBOSE=1; shift ;;
            --noninteractive) NON_INTERACTIVE=1; shift ;;
            --noselenium) NO_SELENIUM=1; shift ;;
            --nocourse) NO_COURSE=1; shift ;;
            --forcedrop) DROP_SITE=1; shift ;;
            --execute)
                case "$2" in
                    *) TEST_TO_EXECUTE=$2 ; shift 2 ;;
                esac ;;
            --moodlepath)
                case "$2" in
                    *) MOODLE_PATH=$2 ; shift 2 ;;
                esac ;;
            --phpversion)
                case "$2" in
                    "") PHP_VERSION="7.0.4" ; shift 2 ;;
                    *) PHP_VERSION=$2 ; shift 2 ;;
                esac ;;
            --phpdocker)
                case "$2" in
                    *) PHP_SERVER_DOCKER=$2 ; shift 2 ;;
                esac ;;
            --seleniumdocker)
                case "$2" in
                    *) SELENIUM_DOCKER=$2 ; shift 2 ;;
                esac ;;
            --dbdockercmd)
                case "$2" in
                    *) DB_DOCKER_TO_START_CMD=$2 ; shift 2 ;;
                esac ;;
            --shareddir)
                case "$2" in
                    *) SERVER_FAIL_DUMP_DIR=$2 ; shift 2 ;;
                esac ;;
            --shareddatadir)
                case "$2" in
                    *) SERVER_DATA_DIR=$2 ; shift 2 ;;
                esac ;;
            --user)
                case "$2" in
                    *) DOCKER_USER=$2 ; shift 2 ;;
                esac ;;
            --git)
                case "$2" in
                    *) GITREPOSITORY=$2 ; shift 2 ;;
                esac ;;
            --branch)
                case "$2" in
                    *) GITBRANCH=$2 ; shift 2 ;;
                esac ;;
            --remote)
                case "$2" in
                    *) GITREMOTE=$2 ; shift 2 ;;
                esac ;;
            --dbhost)
                case "$2" in
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
            -p|--profile)
               case "$2" in
                    "") BEHAT_PROFILE=firefox ; shift 2 ;;
                    *) BEHAT_PROFILE=$2 ; shift 2 ;;
                esac ;;
            --behatdbprefix)
                case "$2" in
                    "") BEHAT_DB_PREFIX="b_" ; shift 2 ;;
                    *) BEHAT_DB_PREFIX=$2 ; shift 2 ;;
                esac ;;
            --seleniumurl)
                case "$2" in
                    "") SELENIUM_URLS=${SELENIUM_URLS} ; shift 2 ;;
                    *) SELENIUM_URLS=$2 ; shift 2 ;;
                esac ;;
            -r|--run)
                case "$2" in
                    "") BEHAT_RUN=${BEHAT_RUN} ; shift 2 ;;
                    *) BEHAT_RUN=$2 ; shift 2 ;;
                esac ;;
            -j|--totalruns)
                case "$2" in
                    "") BEHAT_TOTAL_RUNS=${BEHAT_TOTAL_RUNS} ; shift 2 ;;
                    *) BEHAT_TOTAL_RUNS=$2 ; shift 2 ;;
                esac ;;
            -t|--tags)
                case "$2" in
                    "") BEHAT_TAGS="" ; shift 2 ;;
                    *) BEHAT_TAGS="--tags=\"$2\"" ; shift 2 ;;
                esac ;;
            -f|--feature)
                case "$2" in
                    *) BEHAT_FEATURE=$2 ; shift 2 ;;
                esac ;;
            --suite)
                case "$2" in
                    "") BEHAT_SUITE="" ; shift 2 ;;
                    *) BEHAT_SUITE=$2 ; shift 2 ;;
                esac ;;
            -n|--name)
                case "$2" in
                    "") BEHAT_NAME="" ; shift 2 ;;
                    *) BEHAT_NAME="--name=\"$2\"" ; shift 2 ;;
                esac ;;
            --phpunitdbprefix)
                case "$2" in
                    "") PHPUNIT_DB_PREFIX=${PHPUNIT_DB_PREFIX} ; shift 2 ;;
                    *) PHPUNIT_DB_PREFIX=$2 ; shift 2 ;;
                esac ;;
            --test)
                case "$2" in
                    "") PHPUNIT_TEST="" ; shift 2 ;;
                    *) PHPUNIT_TEST=" \"$2\"" ; shift 2 ;;
                esac ;;
            --filter)
                case "$2" in
                    "") PHPUNIT_FILTER=${PHPUNIT_FILTER} ; shift 2 ;;
                    *) PHPUNIT_FILTER="--filter=\"$2\"" ; shift 2 ;;
                esac ;;
            --logjunit)
                case "$2" in
                    *) LOG_JUNIT="\"$2\"" ; shift 2 ;;
                esac ;;
            --stoponfail) STOP_ON_FAIL='--stop-on-failure'; shift ;;
            --onlysetup) ONLY_SETUP=1; shift ;;
            --) shift; break;;
            *) echo "Check options" ; usage ; exit 1 ;;
        esac
    done
}

# Show error properly.
# @param $1 message to show.
# @param $2 (optional) warn, default is err.
show_error() {
    if [ -n "$2" ] && [ "$2" == "warn" ]; then
        prefix="**WARN:"
    else
        prefix="**ERR:"
    fi

    echo ""
    echo ${prefix} ${1}
    echo ""
}

# Show display if verbose.
log() {
    if [ -n "$SHOW_VERBOSE" ]; then
        echo "$1"
    fi
}

# Check if required run parameters are correct.
check_run_required_params() {
    # Moodle path should be defined.
    if [ -z "$MOODLE_PATH" ] || [ "$MOODLE_PATH" == "" ] || [ ! -d "$MOODLE_PATH" ] || [ ! -f "$MOODLE_PATH/version.php" ]; then
        show_error 'Moodle path is not passed or incorrect. You should pass --moodlepath={ABSOLUTE_PATH_TO_MOODLE}'
        usage
        exit 1
    fi

    # Test to execute should be defined.
    if [ -z "$TEST_TO_EXECUTE" ] || [ "$TEST_TO_EXECUTE" == "" ] || [ "$TEST_TO_EXECUTE" != "behat" ] && [ "$TEST_TO_EXECUTE" != "phpunit" ] && [ "$TEST_TO_EXECUTE" != "moodle" ]; then
        show_error 'Test to execute should be either phpunit or behat. Pass --execute=phpunit or --execute=behat'
        usage
        exit 1
    fi
}

# Pass first argument which user has passed.
# @param $1 phpversion passed by user.
get_php_version_to_use() {

    # If php version is not specified then use default version.
    if [ -z "$1" ] || [ "$1" == "" ]; then
        PHP_VERSION=$DEFAULT_DOCKER_PHP_VERSION
        return 0
    fi

    # Check if version passed is correct.
    for version in "${SUPPORTED_PHP_VERSIONS[@]}"; do
        if [ "$version" == "$1" ] ; then
            return 0
        fi
    done
    # If exact match is not found then check partial check.
    for version in "${SUPPORTED_PHP_VERSIONS[@]}"; do
        if [[ "$version" == "$1"* ]] ; then
            PHP_VERSION=$version
            return 0
        fi
    done

    # If nothing found then use default version DEFAULT_DOCKER_PHP_VERSION
    echo "Docker instance for required php version '$1' is not yet supported, using $DEFAULT_DOCKER_PHP_VERSION"
    PHP_VERSION=$DEFAULT_DOCKER_PHP_VERSION
    return 1
}

# Create db instance if dbhost not passed.
create_db_instance() {
    # If db is not passed then start postgres instance.
    # Default value for DBTYPE is pgsql and user/pass is moodle. So just checking host is fine.
    if [ -z "$DBHOST" ]; then
        # Default dbtype to use is pgsql
        if [ -z "$DBTYPE" ]; then
            DBTYPE="pgsql"
        fi

        if [ "$DBTYPE" = "pgsql" ]; then
            create_pgsql_db_instance
        elif [ "$DBTYPE" = "mysqli" ]; then
            create_mysqli_db_instance
        elif [ "$DBTYPE" = "mariadb" ]; then
            create_mariadb_db_instance
        elif [ "$DBTYPE" = "oci" ]; then
            create_oci_db_instance
        elif [ "$DBTYPE" = "sqlsrv" ]; then
            create_sqlsrv_db_instance
        elif [ "$DBTYPE" = "mssql" ]; then
            create_sqlsrv_db_instance
        fi

    fi
}

# Create postgres db instance.
create_pgsql_db_instance() {
    log "Starting postgres database instance"
    DOCKER_DB_INSTANCE=$(${DB_DOCKER_TO_START_CMD})
    # Wait for 5 seconds to ensure we have postgres docker initialized.
    sleep $WAIT_AFTER_DOCKER_INSTANCE_CREATED

    LINK_DB="--link ${DOCKER_DB_INSTANCE}:DB"

    DBHOST=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_DB_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$DBHOST" ] || [ "$DBHOST" == "" ]; then
        DBHOST=$(docker inspect $DOCKER_DB_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi
    DBNAME="moodle"
    DBUSER="moodle"
    DBPASS="moodle"
    log "Postgres DBHOST is $DBHOST"
}

# Create mysqli db instance
create_mysqli_db_instance() {
    log "Starting Mysql database instance"
    DB_DOCKER_TO_START_CMD='docker run -e  MYSQL_ROOT_PASSWORD=moodle -e MYSQL_DATABASE=moodle -e MYSQL_USER=moodle -e MYSQL_PASSWORD=moodle -d mysql/mysql-server:latest'
    DOCKER_DB_INSTANCE=$(${DB_DOCKER_TO_START_CMD})
    # Wait for 10 seconds to ensure we have postgres docker initialized.
    sleep $WAIT_AFTER_DOCKER_INSTANCE_CREATED
    # Check if db is ready.
    test=$(docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SHOW databases;')
    if [ $? -ne 0 ]; then
        sleep 20
    fi

    LINK_DB="--link ${DOCKER_DB_INSTANCE}:DB"

    DBHOST=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_DB_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$DBHOST" ] || [ "$DBHOST" == "" ]; then
        DBHOST=$(docker inspect $DOCKER_DB_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi

    # Set db to be used by moodle testing.
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'ALTER DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;'
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SET GLOBAL innodb_file_per_table=1;' moodle
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SET GLOBAL innodb_file_format=Barracuda;' moodle

    DBNAME="moodle"
    DBUSER="moodle"
    DBPASS="moodle"
    log "Mysql DBHOST is $DBHOST"
}

# Create mysqli db instance
create_mariadb_db_instance() {
    log "Starting Mariadb database instance"
    DB_DOCKER_TO_START_CMD='docker run -e  MYSQL_ROOT_PASSWORD=moodle -e MYSQL_DATABASE=moodle -e MYSQL_USER=moodle -e MYSQL_PASSWORD=moodle -d mariadb:latest'
    DOCKER_DB_INSTANCE=$(${DB_DOCKER_TO_START_CMD})
    # Wait for 10 seconds to ensure we have postgres docker initialized.
    sleep $WAIT_AFTER_DOCKER_INSTANCE_CREATED
    # Check if db is ready.
    test=$(docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SHOW databases;')
    if [ $? -ne 0 ]; then
        sleep 20
    fi

    LINK_DB="--link ${DOCKER_DB_INSTANCE}:DB"

    DBHOST=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_DB_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$DBHOST" ] || [ "$DBHOST" == "" ]; then
        DBHOST=$(docker inspect $DOCKER_DB_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi

    # Set db to be used by moodle testing.
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'ALTER DATABASE moodle DEFAULT CHARACTER SET utf8 COLLATE utf8_bin;'
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SET GLOBAL innodb_file_per_table=1;' moodle
    docker exec $DOCKER_DB_INSTANCE mysql -uroot -pmoodle -e 'SET GLOBAL innodb_file_format=Barracuda;' moodle

    DBNAME="moodle"
    DBUSER="moodle"
    DBPASS="moodle"
    log "Mariadb DBHOST is $DBHOST"
}

# Create mysqli db instance
create_oci_db_instance() {
    log "Starting Oracle database instance"
    DB_DOCKER_TO_START_CMD='docker run -d -e ORACLE_ALLOW_REMOTE=true rajeshtaneja/oracle-xe-11g'
    DOCKER_DB_INSTANCE=$(${DB_DOCKER_TO_START_CMD})
    # Wait for 5 seconds to ensure we have postgres docker initialized.
    sleep $WAIT_AFTER_DOCKER_INSTANCE_CREATED

    LINK_DB="--link ${DOCKER_DB_INSTANCE}:DB"

    DBHOST=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_DB_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$DBHOST" ] || [ "$DBHOST" == "" ]; then
        DBHOST=$(docker inspect $DOCKER_DB_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi

    DBNAME="xe"
    DBUSER="system"
    DBPASS="oracle"
    log "Oracle DBHOST is $DBHOST"
}

# Create mysqli db instance
create_sqlsrv_db_instance() {
    log "Starting $DBTYPE database instance"
    DB_DOCKER_TO_START_CMD='docker run -e ACCEPT_EULA=Y -e SA_PASSWORD=Passw0rd! -d microsoft/mssql-server-linux'
    DOCKER_DB_INSTANCE=$(${DB_DOCKER_TO_START_CMD})
    # Wait for 20 seconds to ensure we have postgres docker initialized.
    sleep $WAIT_AFTER_DOCKER_INSTANCE_CREATED
    TEST=sqlcmd -S $DBHOST -U SA -P 'Passw0rd!'

    LINK_DB="--link ${DOCKER_DB_INSTANCE}:DB"

    DBHOST=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_DB_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$DBHOST" ] || [ "$DBHOST" == "" ]; then
        DBHOST=$(docker inspect $DOCKER_DB_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi

    # Expects you to have sqlcmd.
    # sudo apt-get update
    # sudo apt-get install mssql-tools
    currentpath=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
    sqlcmd -S $DBHOST -U SA -P 'Passw0rd!' < $currentpath/../mssql/mssql_answer.txt

    DBNAME="moodle"
    DBUSER="sa"
    DBPASS="Passw0rd!"
    log "$DBTYPE DBHOST is $DBHOST"
}

# Create selenium instance.
create_selenium_instance() {
    # If running behat then create selenium instance.
    if [ -n "$NO_SELENIUM" ] || [ "$TEST_TO_EXECUTE" == "phpunit" ]; then
        return 0
    fi

    if [ -n "$SELENIUM_URLS" ] && [ "$SELENIUM_URLS"  != "" ] && [ "$SELENIUM_URLS"  -ne 0 ]; then
        return 0
    fi

    # If no profile passed then consider it as firefox.
    if [ -z "$BEHAT_PROFILE" ] || [ "$BEHAT_PROFILE" == "" ]; then
        BEHAT_PROFILE=""
    fi

    if [ "$BEHAT_PROFILE" == "chrome" ]; then
        SHMMAP="-v /dev/shm:/dev/shm"
    else
        SHMMAP=''
    fi

    # All ports starts with 4444
    DRIVER_PORT=4444
    # Expose all the ports for which selenium is being created.
    # BEHAT_TOTAL_RUNS - BEHAT_RUNS
    EXPOSE="--expose "
    PORTS=""
    addhyphen=0
    # If multiple behat runs, then create multiple selenium instances.
    if [[ -z ${BEHAT_RUN} ]]; then
        BEHAT_RUN="0" # Process number
    fi
    if [[ -z ${BEHAT_TOTAL_RUNS} ]]; then
        BEHAT_TOTAL_RUNS="1" # Total number of processes
    fi

    if [[ "${BEHAT_RUN}" = "0" ]]; then
        runs=$((${BEHAT_TOTAL_RUNS} - ${BEHAT_RUN}))
        for ((i=0;i<${runs};i+=1)); do
            if [ $addhyphen -gt 0 ]; then
                EXPOSE="${EXPOSE}-"
            fi
            addhyphen=$(($addhyphen+1))
            EXPOSE="${EXPOSE}"$(($DRIVER_PORT+$i))
            PORTS="$PORTS "$(($DRIVER_PORT+$i))
        done
    else
        EXPOSE=${EXPOSE}${DRIVER_PORT}
        PORTS=$DRIVER_PORT
    fi

    # Start phantomjs instance.
    if [ -z "$SELENIUM_DOCKER" ]; then
        log "Starting $DEFAULT_SELENIUM_DOCKER"
        SELENIUM_DOCKER="$DEFAULT_SELENIUM_DOCKER $BEHAT_PROFILE"
        # Use copy of the code, so it doesn't depend on the host code.
        DOCKER_SELENIUM_INSTANCE=$(docker run -d $EXPOSE $SHMMAP -v ${MOODLE_PATH}/:/moodle $SELENIUM_DOCKER $PORTS)
    else
        DOCKER_SELENIUM_INSTANCE=$(docker run -d $SHMMAP -v ${MOODLE_PATH}/:/var/www/html/moodle $SELENIUM_DOCKER)
    fi

    LINK_SELENIUM="--link ${DOCKER_SELENIUM_INSTANCE}:SELENIUM_DOCKER"

    # Get selenium docker instance ip.
    SELENIUMIP=$(docker inspect -f "{{ .NetworkSettings.IPAddress }}" $DOCKER_SELENIUM_INSTANCE)
    # IPAddress can be different with the way it is used on system, so grep it.
    if [ -z "$SELENIUMIP" ] || [ "$SELENIUMIP" == "" ]; then
        SELENIUMIP=$(docker inspect $DOCKER_SELENIUM_INSTANCE | grep '"IPAddress": \+' | sed -rn '/([0-9]{1,3}\.){3}[0-9]{1,3}/p' | sed '$!d' | sed 's#.* "##' | sed 's#",##')
    fi


    SELENIUMURL="--seleniumurl="
    for p in $PORTS; do
        SELENIUMURL=${SELENIUMURL}${SELENIUMIP}:$p","
    done

    SELENIUMURL=${SELENIUMURL::-1}
    log "Selenium url is $SELENIUMURL"
    # Wait for 5 seconds to ensure we have selenium docker initialized.
    sleep 5
}

start_php_server_and_run_test() {
    # Set docker instance to use if phpdocker is not passed.
    if [ -z "$PHP_SERVER_DOCKER" ]; then
        get_php_version_to_use $PHP_VERSION
        PHP_SERVER_DOCKER="rajeshtaneja/php:${PHP_VERSION}"
        # If db is oci or mssql then ensure we don't use php7.
        if [ "$DBTYPE" == "mssql" ] || [ "$DBTYPE" == "oci" ]; then
            if [ "$PHP_SERVER_DOCKER" == "rajeshtaneja/php:7.0.4" ]; then
                show_error "PhP 7 is not yet supporting $DBTYPE"
                exit 1
            fi
        fi
    fi
    log "php docker image $PHP_SERVER_DOCKER is being used"

    # Docker name to use for php docker instance. We need this as it can be run in a process.
    local randominstance=$(( ( RANDOM % 100 )  + 1 ))
    if [ "$TEST_TO_EXECUTE" == "behat" ]; then
        PHP_DOCKER_NAME=$(echo "${MOODLE_PATH}_${TEST_TO_EXECUTE}_${MOODLE_BRANCH}_${BEHAT_PROFILE}_${BEHAT_RUN}_${randominstance}" | sed 's,/,_,g' | sed 's/_//1')
    elif [ "$TEST_TO_EXECUTE" == "phpunit" ]; then
        PHP_DOCKER_NAME=$(echo "${MOODLE_PATH}_${TEST_TO_EXECUTE}_${MOODLE_BRANCH}_${DBTYPE}_${randominstance}" | sed 's,/,_,g' | sed 's/_//1')
    elif [ "$TEST_TO_EXECUTE" == "moodle" ]; then
        PHP_DOCKER_NAME=$(echo "${MOODLE_PATH}_${TEST_TO_EXECUTE}_${MOODLE_BRANCH}_${randominstance}" | sed 's,/,_,g' | sed 's/_//1')
    else
       echo "TEST_TO_EXECUTE should not be $TEST_TO_EXECUTE"
       usage 1
    fi

    if [ -z "$DOCKER_USER" ] || [ "$DOCKER_USER" == "" ]; then
        DOCKER_USER="moodle"
    fi

    # If asked to use host code then map to /var/www/html/moodle.
    if [ -z "$DOCKER_USE_HOST_CODE" ] || [ "$DOCKER_USE_HOST_CODE" == "" ]; then
        DOCKER_MOODLE_PATH="/moodle"
    else
        DOCKER_MOODLE_PATH="/var/www/html/moodle"
    fi

    # If asked to use host code then map to /var/www/html/moodle.
    if [ -z "$SERVER_FAIL_DUMP_DIR" ] || [ "$SERVER_FAIL_DUMP_DIR" == "" ]; then
        DOCKER_FAIL_DUMP_MAP=""
    else
        DOCKER_FAIL_DUMP_MAP="-v ${SERVER_FAIL_DUMP_DIR}/:/shared"
    fi

    # If asked to use host code then map to /var/www/html/moodle.
    if [ -z "$SERVER_DATA_DIR" ] || [ "$SERVER_DATA_DIR" == "" ]; then
        DOCKER_DATA_MAP=""
    else
        DOCKER_DATA_MAP="-v ${SERVER_DATA_DIR}/:/shared_data"
    fi

    passdbhost=""
    if [ -n "$LINK_DB" ]; then
        passdbhost="--dbhost=$DBHOST"
        if [ -n "$DBNAME" ]; then
            passdbhost="${passdbhost} --dbname=$DBNAME"
        fi
        if [ -n "$DBUSER" ]; then
            passdbhost="${passdbhost} --dbuser=$DBUSER"
        fi
        if [ -n "$DBPASS" ]; then
            passdbhost="${passdbhost} --dbpass=$DBPASS"
        fi
        if [ -n "$DBPORT" ]; then
            passdbhost="${passdbhost} --dbport=$DBPORT"
        fi
    fi

    local dockerrunmode="-ti"
    if [ -n "$NON_INTERACTIVE" ]; then
        dockerrunmode="-i"
    fi

    if [ "$TEST_TO_EXECUTE" == "behat" ]; then
        cmd="docker run ${dockerrunmode} --rm --user=${DOCKER_USER} --name ${PHP_DOCKER_NAME} \
            -v ${MOODLE_PATH}/:${DOCKER_MOODLE_PATH} ${DOCKER_FAIL_DUMP_MAP} ${DOCKER_DATA_MAP} ${LINK_SELENIUM}  ${LINK_DB}\
            ${PHP_SERVER_DOCKER} /scripts/behat.sh $passdbhost $SELENIUMURL $ORGINIAL_USER_OPTS"

        log "Executing: $cmd"
        eval $cmd
        EXITCODE=$?
    elif [ "$TEST_TO_EXECUTE" == "phpunit" ]; then
        cmd="docker run ${dockerrunmode} --rm --user=${DOCKER_USER} --name ${PHP_DOCKER_NAME} \
            -v ${MOODLE_PATH}/:${DOCKER_MOODLE_PATH} ${DOCKER_DATA_MAP} ${LINK_DB} ${PHP_SERVER_DOCKER} /scripts/phpunit.sh $passdbhost $ORGINIAL_USER_OPTS"

        log "Executing: $cmd"
        eval $cmd
        EXITCODE=$?
    else
        cmd="docker run ${dockerrunmode} --rm --user=${DOCKER_USER} --name ${PHP_DOCKER_NAME}"
        cmd="$cmd -v ${MOODLE_PATH}/:${DOCKER_MOODLE_PATH} ${DOCKER_FAIL_DUMP_MAP} ${DOCKER_DATA_MAP} ${LINK_SELENIUM} ${LINK_DB}"
        cmd="$cmd ${PHP_SERVER_DOCKER} /scripts/moodle.sh $passdbhost $SELENIUMURL $ORGINIAL_USER_OPTS"

        log "Executing: $cmd"
        eval $cmd
        RUNNING_DOCKER_PHP=$(docker inspect --format="{{ .State.Running }}" $PHP_DOCKER_NAME > /dev/null 2>&1)
        EXITCODE=RUNNING_DOCKER_PHP
    fi
}

# Download composer.phar and install composer before you go to container. As it will be faster.
update_composer_on_host() {
    local whereami="${PWD}"
    cd $MOODLE_PATH
    if [ ! -f "$MOODLE_PATH/composer.phar" ]; then
        curl -s https://getcomposer.org/installer | php
    fi

    php composer.phar install --prefer-dist --no-interaction
    cd $whereami
}

# Stop all instances
stop_all_instances() {
    # Stop db docker instance if created.
    docker inspect $DOCKER_DB_INSTANCE  > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "Stopping database $DBTYPE docker instance..."
        docker stop $DOCKER_DB_INSTANCE
        docker rm $DOCKER_DB_INSTANCE
        DB_STOPPED=1
    fi

    docker inspect $DOCKER_SELENIUM_INSTANCE  > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "Stopping selenium docker instance..."
        docker stop $DOCKER_SELENIUM_INSTANCE
        docker rm $DOCKER_SELENIUM_INSTANCE
    fi

    docker inspect $PHP_DOCKER_NAME  > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        log "Stopping php docker instance..."
        docker stop ${PHP_DOCKER_NAME}
    fi
}