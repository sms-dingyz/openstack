#!/usr/bin/env bash

mysql -u keystone -p"$KEYSTONE_DBPASS" keystone -h controller -e quitset -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Set up keystone for controller node
#------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prerequisites
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Setting up database for keystone."
setup_database keystone "$KEYSTONE_DB_USER" "$KEYSTONE_DBPASS"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Not in install-guide:

echo "Sanity check: local auth should work."
mysql -u keystone -p"$KEYSTONE_DBPASS" keystone -e quit


echo "Sanity check: remote auth should work."
mysql -u keystone -p"$KEYSTONE_DBPASS" keystone -h controller -e quit

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure components
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

conf=/etc/keystone/keystone.conf
echo "Editing $conf."

function get_database_url {
    local db_user=$KEYSTONE_DB_USER
    local database_host=controller

    echo "mysql+pymysql://$db_user:$KEYSTONE_DBPASS@$database_host/keystone"
}

database_url=$(get_database_url)

echo "Setting database connection: $database_url."
iniset_sudo $conf database connection "$database_url"

echo "Configuring the Fernet token provider."
iniset_sudo $conf token provider fernet

echo "Creating the database tables for keystone."
sudo keystone-manage db_sync

echo "Initializing Fernet key repositories."
sudo keystone-manage fernet_setup \
    --keystone-user keystone \
    --keystone-group keystone

sudo keystone-manage credential_setup \
    --keystone-user keystone \
    --keystone-group keystone

echo "Bootstrapping the Identity service."
sudo keystone-manage bootstrap --bootstrap-password "$ADMIN_PASS" \
    --bootstrap-admin-url http://controller:5000/v3/ \
    --bootstrap-internal-url http://controller:5000/v3/ \
    --bootstrap-public-url http://controller:5000/v3/ \
    --bootstrap-region-id "$REGION"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Apache HTTP server
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

conf=/etc/apache2/apache2.conf
echo "Configuring ServerName option in $conf to reference controller node."
echo "ServerName controller" | sudo tee -a $conf


conf=/etc/apache2/sites-enabled/keystone.conf
if [ -f $conf ]; then
    echo "Identity service virtual hosts enabled."
else
    echo "Identity service virtual hosts not enabled."
    exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Reduce memory usage (not in install-guide)
sudo sed -i --follow-symlinks '/WSGIDaemonProcess/ s/processes=[0-9]*/processes=1/' $conf
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finalize the installation
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Restarting apache."
sudo systemctl restart  apache2
sudo systemctl enable  apache2
