#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

sudo apt install python3-rbd
sudo apt install ceph-common

#------------------------------------------------------------------
# copy ceph.conf to controller
#------------------------------------------------------------------

node_ssh ceph-admin "sudo scp /etc/ceph/ceph.conf controller:/etc/ceph/"

#confiure glance-api.conf
conf = /etc/glance/glance-api.conf
sudo ceph auth get-or-create client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children,allow rwx pool=glance-images'

keyring = /etc/ceph/ceph.client.glance.keyring
sudo ceph auth get-or-create client.glance | node_ssh controller "sudo tee $keyring"
node_ssh controller "chown $USER:$USER $keyring"


iniset_sudo $keyring "caps mon" "'allow r'"
iniset_sudo $keyring "caps osd" "'allow class-read object_prefix rbd_children, allow rwx pool=glance-images'"

#restart glance-api.service
sudo systemctl restart glance-api


#set permissions
sudo chgrp $USER $keyring
sudo chmod 0640 $keyring
