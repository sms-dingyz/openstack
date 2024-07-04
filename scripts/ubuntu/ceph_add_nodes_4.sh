#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto

exec_logfile
#----------------------------------------------------------------------------
#add ceph monitor node to ceph cluster
#----------------------------------------------------------------------------

#add monitor node to the cluster(in our solution there are 3 monitor nodes,ceph-mon01 ceph-mon02
#ceph-mon03
# ensure you have copied the ceph ssh public key
for i in 02 03 ; do sudo ceph orch host add ceph-mon$i; done
for i in 01 02 03 ; do sudo ceph orch host label add ceph-mon$i mon$i; done

#------------------------------------------------------------------------------------
#add ceph osd nodes to ceph cluster
#------------------------------------------------------------------------------------
for i in 01 02 03 ; do sudo ceph orch host add ceph-osd$i; done
for i in 01 02 03 ; do sudo ceph orch host label add ceph-osd$i osd$i; done



#------------------------------------------------------------------------------------
#ist ceph cluster nodes
#------------------------------------------------------------------------------------
echo "list Ceph cluster nodes..."
sudo ceph orch host ls
