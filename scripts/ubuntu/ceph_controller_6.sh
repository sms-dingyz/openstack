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

iniset_sudo $conf glance_store stores rbd
iniset_sudo $conf glance_store default_store rbd
iniset_sudo $conf glance_store rbd_store_chunk_size 8
iniset_sudo $conf glance_store rbd_store_pool  glance-images
iniset_sudo $conf glance_store rbd_store_user  $USER
iniset_sudo $conf glance_store rbd_store_ceph_conf /etc/ceph/ceph.con
iniset_sudo $conf glance_store show_image_direct_url True

#restart glance-api.service
sudo systemctl restart glance-api
