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



echo "Restarting apache."
sudo systemctl restart  apache2
sudo systemctl enable  apache2

# Set environment variables for authentication
export OS_USERNAME=$ADMIN_USER_NAME
export OS_PASSWORD=$ADMIN_PASS
export OS_PROJECT_NAME=$ADMIN_PROJECT_NAME
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3

#------------------------------------------------------------------------------
# Create a domain, projects, users, and roles
#------------------------------------------------------------------------------

# Wait for keystone to come up
wait_for_keystone

# Not creating domain because default domain has already been created by


#------------------------------------------------------------------------------
# Verify operation
#------------------------------------------------------------------------------

echo "Verifying keystone installation."

# From this point on, we are going to use keystone for authentication
unset OS_AUTH_URL OS_PASSWORD

echo "Requesting an authentication token as an admin user."
openstack \
    --os-auth-url http://controller:5000/v3 \
    --os-project-domain-name Default \
    --os-user-domain-name Default \
    --os-project-name "$ADMIN_PROJECT_NAME" \
    --os-username "$ADMIN_USER_NAME" \
    --os-auth-type password \
    --os-password "$ADMIN_PASS" \
    token issue

echo "Requesting an authentication token for the demo user."
openstack \
    --os-auth-url http://controller:5000/v3 \
    --os-project-domain-name Default \
    --os-user-domain-name Default \
    --os-project-name "$DEMO_PROJECT_NAME" \
    --os-username "$DEMO_USER_NAME" \
    --os-auth-type password \
    --os-password "$DEMO_PASS" \
    token issue
