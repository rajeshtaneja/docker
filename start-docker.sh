#!/bin/bash

# Usage o/p
function usage() {
cat << EOF
################################### Usage ##########################################
#                                                                                  #
#                          Start Moodle docker container                           #
#                                                                                  #
####################################################################################
# ./start-docker.sh --name='nmoodle --moodlepath='/PAT/TO/MOODLE/ON/HOST'          #
#   -n|--name: Name of docker container                                            #
#   -p|--path: Path to moodle dir on host machine                                  #
#   -h|--help : Help                                                               #
#                                                                                  #
####################################################################################
EOF
    exit 0
}

# get user options.
OPTS=`getopt -o n:p::h --long name:,moodlepath::,help -- "$@"`
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
        -n|--name)
            case "$2" in
                *) CONTAINERNAME=$2 ; shift 2 ;;
            esac ;;
        -p|--moodlepath)
            case "$2" in
                "") shift 2 ;;
                *) MOODLEDIR=$2 ; shift 2 ;;
            esac ;;
        --) shift; break;;
        *) echo "Check options" ; usage ; exit 1 ;;
    esac
done

docker run -d --name moodledb -e POSTGRES_USER=moodle -e POSTGRES_PASSWORD=moodle postgres

# Wait for 10 seconds to ensure we have postgres docker intialised.
sleep 10
if [[ -z ${MOODLEDIR} ]]; then
    docker run -d -P --name ${CONTAINERNAME} --link moodledb:DB rajeshtaneja/moodle:master /scripts/init.sh
else
    docker run -d -P --name ${CONTAINERNAME} -v ${MOODLEDIR}:/var/www/html/moodle --link moodledb:DB moodlehq/moodle:master /scripts/init.sh
fi

# Wait for 5 seconds to ensure we have docker initialised.
sleep 5
IP=$(docker logs moodle | grep "# IP:" | sed 's/## IP: //g')

echo "#######################################################################"
echo "##  You can access moodle via http://${IP}/moodle"
echo "##  Username/password: admin/moodle"
echo "## Access container via 'docker exec -ti ${CONTAINERNAME} bash'"
echo "#######################################################################"

