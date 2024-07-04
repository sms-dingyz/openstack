#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

#--------------------------------------------------------
#copy ceph.conf to controller and compute node
#--------------------------------------------------------

sudo scp /etc/ceph/ceph.conf controller:/etc/ceph
sudo scp /etc/ceph/ceph.conf compute01:/etc/ceph
