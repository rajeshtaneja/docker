#!/bin/bash
# This script is for docker input to customise and run behat.

# Exit on errors.
#set -e
RUNNING_TEST='behat'

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
############################################ Usage ###############################################
#                                                                                                #
#                                          Run behat                                             #
#                                                                                                #
##################################################################################################
# docker run --rm -v PATH_TO_MOODLE:/moodle -v /shared:/shared rajeshtaneja/php:7.0 /behat       #
#   --dbtype/dbname/dbhost/dbuser/dbpass : Database details                                      #
#   --behatdbprefix: Behat db prefix (default is b_)                                             #
#   --profile/tags/feature/name/suite : Behat specific options                                   #
#   --run/totalruns : Process to run out of how many processes                                   #
#   --stoponfail: Stop on fail                                                                   #
#   --git : (optional) git Repository                                                            #
#   --remote: (optional) git remote                                                              #
#   --branch : (optional) Branch to use                                                          #
#   -h : Help                                                                                    #
#                                                                                                #
##################################################################################################
EOF
    exit 1
}

# echo build details
function echo_build_details() {
    echo "###########################################"
    echo "#   $1 on: ${PHPVERSION}"
    echo "###########################################"
    echo "## Git Repository: ${GITREPOSITORY}"
    echo "## Git Branch: ${GITBRANCH}"
    echo "## DB Host: ${DBHOST}"
    echo "## DB TYPE: ${DBTYPE}"
    echo "## PROCESS: ${BEHAT_RUN}/${BEHAT_TOTAL_RUNS}"
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
    if [[ -n ${BEHAT_SUITE} ]]; then
        echo "## Behat suite: ${BEHAT_SUITE}"
    fi
    echo "## IP: ${DOCKERIP}"
    echo "###########################################"
}


function is_single_run() {
    if [ -z "$BEHAT_TOTAL_RUNS" ] || [ "$BEHAT_TOTAL_RUNS" == "" ] || [ "$BEHAT_TOTAL_RUNS" -eq 1 ]; then
        SINGLE_PROCESS=1
    fi

    if [ "$BEHAT_RUN"  -le 1 ] && [ "$BEHAT_TOTAL_RUNS" -le 1 ]; then
        SINGLE_PROCESS=1
    fi

    if [ -z "$BEHAT_RUN" ] || [ "$BEHAT_RUN" == "" ] || [ "$BEHAT_RUN" -eq 0 ] ; then
        if [ "$BEHAT_TOTAL_RUNS" -gt 1 ]; then
            SINGLE_PROCESS_WITH_MULTIPLE_RUNS=1
        fi
    elif [ "$BEHAT_TOTAL_RUNS" -eq 0 ] && [ "$BEHAT_RUN" -ge 1 ]; then
        SINGLE_PROCESS_WITH_MULTIPLE_RUNS=1
    fi

    if [ "$BEHAT_RUN"  -ge 1 ] && [ "$BEHAT_TOTAL_RUNS" -gt 1 ]; then
        SPECIFIED_RUN=1
    fi
}

#################################################
# Set enviornment to run behat
#################################################
function set_behat_run_env() {
    # Load final variables.
    MOODLE_VERSION=$(grep "\$branch" ${MOODLE_DIR}/version.php | sed "s/';.*//" | sed "s/^\$.*'//")

    # Moodle data dir to create.
    MOODLE_DATA_BASE_DIR=${SHARED_DATA_DIR}/moodledata/${MOODLE_VERSION}/${DBTYPE}
    MOODLE_FAILDUMP_BASE_DIR=${SHARED_DIR}/faildump

    MOODLE_DATA_DIR=${MOODLE_DATA_BASE_DIR}/data
    MOODLE_BEHAT_DATA_DIR=${MOODLE_DATA_BASE_DIR}/behat_data

    # Create data dir if not present. Create it one by one.
    if [ ! -d "${SHARED_DIR}" ]; then
        sudo mkdir -p ${SHARED_DIR}
        sudo chmod -R 777 ${SHARED_DIR}
    fi
    if [ ! -d "${SHARED_DATA_DIR}" ]; then
        sudo mkdir -p ${SHARED_DATA_DIR}
        sudo chmod -R 777 ${SHARED_DATA_DIR}
    fi
    if [ ! -d "$MOODLE_DATA_BASE_DIR" ]; then
        mkdir -p $MOODLE_DATA_BASE_DIR
        chmod 777 -R $MOODLE_DATA_BASE_DIR
    fi
    if [ ! -d "$MOODLE_DATA_DIR" ]; then
        mkdir $MOODLE_DATA_DIR
        chmod 777 -R $MOODLE_DATA_DIR
    fi
    if [ ! -d "$MOODLE_BEHAT_DATA_DIR" ]; then
        mkdir $MOODLE_BEHAT_DATA_DIR
        chmod 777 -R $MOODLE_BEHAT_DATA_DIR
    fi
    if [ ! -d "$MOODLE_FAILDUMP_BASE_DIR" ]; then
        mkdir $MOODLE_FAILDUMP_BASE_DIR
        chmod 777 $MOODLE_FAILDUMP_BASE_DIR
    fi

    # Create behat site data
    if [[ ! -d "$MOODLE_BEHAT_DATA_DIR$BEHAT_RUN" ]]; then
        mkdir -m777 $MOODLE_BEHAT_DATA_DIR$BEHAT_RUN
    fi

    # Behat config file to use.
    if [[ "$MOODLE_VERSION" -ge "31" ]]; then
        BEHAT_CONFIG_FILE=${HOMEDIR}config/config.php.behat3.template
    fi

    # Rerun file to save to.
    RERUN_FILE="${MOODLE_DATA_BASE_DIR}/${GITBRANCH}-rerunlist"

    # Directories shared with host for saving faildump and timing.
    MOODLE_DUMP_DIR=${MOODLE_FAILDUMP_BASE_DIR}/${GITBRANCH}/${BEHAT_PROFILE}
    BEHAT_TIMING_FILE=${MOODLE_DUMP_DIR}/timing.json

    if [[ ! -d ${MOODLE_DUMP_DIR} ]]; then
        mkdir -p ${MOODLE_DUMP_DIR}
        chmod 777 ${MOODLE_DUMP_DIR}
    fi

    is_single_run

    if [ -n "$SINGLE_PROCESS" ] || [ -n "$SINGLE_PROCESS_WITH_MULTIPLE_RUNS" ]; then
        MOODLE_FAIL_DUMP_DIR=${MOODLE_DUMP_DIR}/run
    else
        MOODLE_FAIL_DUMP_DIR=${MOODLE_DUMP_DIR}/run_${BEHAT_RUN}
    fi

    if [[ "$MOODLE_VERSION" -ge "31" ]]; then
        if [ -n "$SINGLE_PROCESS" ]; then
            BEHAT_FORMAT="--format=moodle_progress --out=std"
            BEHAT_OUTPUT="--format=pretty --out=${MOODLE_FAIL_DUMP_DIR}/pretty.txt"
        else
            BEHAT_FORMAT="--format=moodle_progress --out=std"
            BEHAT_OUTPUT="--format=pretty --out=${MOODLE_FAIL_DUMP_DIR}/pretty{runprocess}.txt --replace={runprocess}"
        fi
    else
        if [ -n "$SINGLE_PROCESS" ]; then
            BEHAT_FORMAT="--format='moodle_progress,pretty,html'"
            BEHAT_OUTPUT="--out=',${MOODLE_FAIL_DUMP_DIR}/pretty.txt,${MOODLE_FAIL_DUMP_DIR}/progress.html'"
        else
            BEHAT_FORMAT="--format='moodle_progress,pretty,html'"
            BEHAT_OUTPUT="--out=',${MOODLE_FAIL_DUMP_DIR}/pretty{runprocess}.txt,${MOODLE_FAIL_DUMP_DIR}/progress.html' --replace={runprocess}"
        fi
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

#Setup behat.
function setup_behat() {
    echo "Installing behat for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR

    if [ ! -f "$MOODLE_DIR/composer.phar" ]; then
        curl -s https://getcomposer.org/installer | php
    fi

    php composer.phar install --prefer-dist --no-interaction

    # No need to drop site, init will do the job if needed.
    if [ -n "$DROP_SITE" ]; then
        if [ -n "$DEBUG_ME" ]; then
            echo " ** Droping all sites **"
        fi
        # Drop parallel sites.
        php admin/tool/behat/cli/util.php --drop -j=10
        # Drop single site.
        php admin/tool/behat/cli/util.php --drop
    fi

    # Initialize site for single, parallel or specified run.
    if [ -n "$SINGLE_PROCESS_WITH_MULTIPLE_RUNS" ]; then
        CMD="php admin/tool/behat/cli/init.php -j=$BEHAT_TOTAL_RUNS"

    elif [ -n "$SINGLE_PROCESS" ]; then
        CMD="php admin/tool/behat/cli/init.php"

    elif [ -n "$SPECIFIED_RUN" ]; then
        CMD="php admin/tool/behat/cli/init.php -j=$BEHAT_TOTAL_RUNS --fromrun=$BEHAT_RUN --torun=$BEHAT_RUN"

    else
        show_error "Specified run '$BEHAT_RUN' and total runs '$BEHAT_TOTAL_RUNS' don't make sense"
    fi

    if [ -n "$BEHAT_SUITE" ]; then
        CMD="${CMD} -a=${BEHAT_SUITE}"
    fi
    log "Initializing site with: $CMD"
    eval $CMD
    exitcode=${PIPESTATUS[0]}
    if [ "${exitcode}" -ne 0 ]; then
        show_error "Error while intializing site..."
    fi

    cd ${whereami}
}

# Run behat
function run_behat() {
    echo "Running behat for ${DBTYPE} database"
    whereami="${PWD}"
    cd $MOODLE_DIR

    # If process is not defined or empty then it's a run without from and to.
    if [ -n "$SINGLE_PROCESS" ] || [ -n "$SINGLE_PROCESS_WITH_MULTIPLE_RUNS" ]; then
        FROMRUN=""
        TORUN=""
    else
        FROMRUN="--fromrun=$BEHAT_RUN"
        TORUN="--torun=$BEHAT_RUN"
    fi
    if [ -n "$SPECIFIED_RUN" ] || [ -n "$SINGLE_PROCESS" ]; then
        RERUN_FILE_TO_USE="${RERUN_FILE}"
    else
        RERUN_FILE_TO_USE="${RERUN_FILE}{runprocess}"
    fi

    BEHAT_SUITE_TO_USE=""
    if [ -n "$BEHAT_SUITE" ]; then
        BEHAT_SUITE_TO_USE="--suite=${BEHAT_SUITE}"
    fi

    BEHAT_PROFILE_ORG=$BEHAT_PROFILE
    # Commands for Moodle 31 has chnaged, so do following:
    if [ "$MOODLE_VERSION" -ge "31" ]; then
        if [ -z "$SINGLE_PROCESS" ]; then
            BEHAT_PROFILE="${BEHAT_PROFILE}{runprocess}"
        fi
        CMD="php admin/tool/behat/cli/run.php $BEHAT_FORMAT $BEHAT_OUTPUT $FROMRUN $TORUN -p=$BEHAT_PROFILE $BEHAT_TAGS $STOP_ON_FAIL $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE"
        if [ -n "$LOG_JUNIT" ]; then
            CMD="${CMD} --format=junit --out=${LOG_JUNIT}"
        fi
    else
        if [ -n "$LOG_JUNIT" ]; then
            BEHAT_FORMAT="${BEHAT_FORMAT},junit"
            BEHAT_OUTPUT="${BEHAT_OUTPUT},${LOG_JUNIT}"
        fi
        CMD="php admin/tool/behat/cli/run.php --rerun=\"${RERUN_FILE_TO_USE}.txt\" $BEHAT_FORMAT $BEHAT_OUTPUT $FROMRUN $TORUN -p=$BEHAT_PROFILE $BEHAT_TAGS $STOP_ON_FAIL $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE"
    fi

    log "$CMD"
    eval $CMD
    exitcode=${PIPESTATUS[0]}
    log "** Exit code is: $exitcode **"

    if [[ -n ${STOP_ON_FAIL} ]]; then
        exit $exitcode
    fi

    if [ "${exitcode}" -ne 0 ]; then
        BEHAT_FORMAT=""
        BEHAT_OUTPUT=""
        echo "----------------------------------------------------------------------------------------------"
        echo "!!!---Last exit code is ${exitcode}. Trying failed runs again to remove random failures.---!!!"
        echo "----------------------------------------------------------------------------------------------"
        # Re-run failed scenarios, to ensure they are true fails.
        if [ "$MOODLE_VERSION" -ge "32" ]; then
            # If we are running 1 run single or specified then don't need to check for each run.
            if [ -n "$SPECIFIED_RUN" ] || [ -n "$SINGLE_PROCESS" ]; then
                # If single process then no suffix needed.
                if [ -z "$SPECIFIED_RUN" ]; then
                    BEHAT_RUN=""
                else
                    if [ ! -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                        ln -s $MOODLE_DIR $MOODLE_DIR/behatrun${BEHAT_RUN}
                    fi
                fi
                echo "---Running behat Process ${BEHAT_RUN} again for failed steps---"
                CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR/behatrun${BEHAT_RUN}/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT -p=${BEHAT_PROFILE_ORG}${BEHAT_RUN} $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE --verbose --rerun"
                log "$CMD"
                eval $CMD
                newexitcode=$(($newexitcode+${PIPESTATUS[0]}))
                if [ -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                    rm $MOODLE_DIR/behatrun${BEHAT_RUN}
                fi
            else
                newexitcode=0
                for ((i=1;i<=$BEHAT_TOTAL_RUNS;i+=1)); do
                    status=$((1 << $i-1))
                    CURRENTRUNEXITCODE=$(($status & $exitcode))
                    if [ $CURRENTRUNEXITCODE -ne 0 ]; then
                        echo "---Running behat Process ${i} again for failed steps---"
                        if [ ! -L $MOODLE_DIR/behatrun$i ]; then
                            ln -s $MOODLE_DIR $MOODLE_DIR/behatrun$i
                        fi
                        sleep 5
                        CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR/behatrun${i}/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT -p=${BEHAT_PROFILE_ORG}${i} $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE --verbose --rerun"
                        log "$CMD"
                        eval $CMD
                        newexitcode=$(($newexitcode+${PIPESTATUS[0]}))
                        if [ -L $MOODLE_DIR/behatrun$i ]; then
                            rm $MOODLE_DIR/behatrun$i
                        fi
                    fi
                done;
            fi
        elif [ "$MOODLE_VERSION" -eq "31" ]; then
            # If we are running 1 run single or specified then don't need to check for each run.
            if [ -n "$SPECIFIED_RUN" ] || [ -n "$SINGLE_PROCESS" ]; then
                # If single process then no suffix needed.
                if [ -z "$SPECIFIED_RUN" ]; then
                    BEHAT_RUN=""
                else
                    if [ ! -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                        ln -s $MOODLE_DIR $MOODLE_DIR/behatrun${BEHAT_RUN}
                    fi
                fi
                echo "---Running behat Process ${BEHAT_RUN} again for failed steps---"
                CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR${BEHAT_RUN}/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT -p=${BEHAT_PROFILE_ORG}${BEHAT_RUN} $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE --verbose --rerun"
                log "$CMD"
                eval $CMD
                newexitcode=$(($newexitcode+${PIPESTATUS[0]}))
                if [ -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                    rm $MOODLE_DIR/behatrun${BEHAT_RUN}
                fi
            else
                newexitcode=0
                for ((i=1;i<=$BEHAT_TOTAL_RUNS;i+=1)); do
                    status=$((1 << $i-1))
                    CURRENTRUNEXITCODE=$(($status & $exitcode))
                    if [ $CURRENTRUNEXITCODE -ne 0 ]; then
                        echo "---Running behat Process ${i} again for failed steps---"
                        if [ ! -L $MOODLE_DIR/behatrun$i ]; then
                            ln -s $MOODLE_DIR $MOODLE_DIR/behatrun$i
                        fi
                        sleep 5
                        CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR$i/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT -p=${BEHAT_PROFILE_ORG}${i} $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE --verbose --rerun"
                        log "$CMD"
                        eval $CMD
                        newexitcode=$(($newexitcode+${PIPESTATUS[0]}))
                        if [ -L $MOODLE_DIR/behatrun$i ]; then
                            rm $MOODLE_DIR/behatrun$i
                        fi
                    fi
                done;
            fi
        else
            # If we are running 1 run single or specified then don't need to check for each run.
            if [ -n "$SPECIFIED_RUN" ] || [ -n "$SINGLE_PROCESS" ]; then
                # If single process then no suffix needed.
                thisrerunfile="${RERUN_FILE}.txt"
                if [ -z "$SPECIFIED_RUN" ]; then
                    BEHAT_RUN=""
                else
                    if [ ! -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                        ln -s $MOODLE_DIR $MOODLE_DIR/behatrun${BEHAT_RUN}
                    fi
                fi
                echo "---Running behat Process ${BEHAT_RUN} again for failed steps---"
                CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR${BEHAT_RUN}/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT --verbose --rerun $thisrerunfile -p=$BEHAT_PROFILE $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE"
                log "$CMD"
                eval $CMD
                newexitcode=$(($newexitcode+${PIPESTATUS[0]}))
                if [ -L $MOODLE_DIR/behatrun${BEHAT_RUN} ]; then
                    rm $MOODLE_DIR/behatrun${BEHAT_RUN}
                fi
            else
                exitcode=0
                for ((i=1;i<=$BEHAT_TOTAL_RUNS;i+=1)); do
                    thisrerunfile="${RERUN_FILE}${i}.txt"
                    if [ -e "${thisrerunfile}" ]; then
                        if [ -s "${thisrerunfile}" ]; then
                            echo "---Running behat Process ${i} again for failed steps---"
                            if [ ! -L $MOODLE_DIR/behatrun$i ]; then
                                ln -s $MOODLE_DIR $MOODLE_DIR/behatrun$i
                            fi
                            sleep 5
                            CMD="vendor/bin/behat --config $MOODLE_BEHAT_DATA_DIR$i/behat/behat.yml $BEHAT_FORMAT $BEHAT_OUTPUT --verbose --rerun $thisrerunfile -p=$BEHAT_PROFILE $BEHAT_TAGS $BEHAT_NAME $BEHAT_FEATURE $BEHAT_SUITE_TO_USE"
                            log "$CMD"
                            eval $CMD
                            exitcode=$(($exitcode+${PIPESTATUS[0]}))
                            rm $thisrerunfile
                            if [ -L $MOODLE_DIR/behatrun$i ]; then
                                rm $MOODLE_DIR/behatrun$i
                            fi
                        fi
                    fi
                    newexitcode=$exitcode
                done;
            fi
        fi
    else
        newexitcode=$exitcode
    fi
  log "** Final exit code is: $newexitcode **"
  exit $newexitcode
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

# Set env for behat.
set_behat_run_env

# Start apache.
start_apache

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details "Setup Behat"

# Setup behat.
setup_behat

# If only setup is set then don't run behat.
if [ -z "$ONLY_SETUP" ]; then
    # Show user details about build.
    echo_build_details "Running Behat"

    # Run behat.
    run_behat
fi