sudo apt-get install python-pip libmysqlclient-dev libpq-dev python-dev
# This script is for docker input to customise and run behat.

# Exit on errors.
#set -e

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
# Get user options.
get_user_options "$@"

# Check if required params are set.
check_required_params

# Checkout git branch.
checkout_git_branch

# Start apache.
start_apache

# Set moodle config.
set_moodle_config

# Show user details about build.
echo_build_details

# Install moodle.
install_moodle

echo "Admin account: admin/moodle"

# If passed keep alive then it's interactive mode.
if [[ -z ${KEEPALIVE} ]]; then
    echo "# To access Moodle: http://${DOCKERIPWEB}"
    echo "# user/password: admin/moodle"
    echo "# To enter shell in moodle container shell: docker exec -it {container name} bash"
    tail -F /var/log/apache2/*
else
    bash
fi