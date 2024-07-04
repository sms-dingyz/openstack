#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto
#---------------------------------------------------------------------
# 1. the deivce must have no partitions
# 2. the device must not have any LVM state
# 3. the device must not be mounted 
# you can use umount /deve/sdx to umount device on each osd node
# 4. the device must not contain a file system
# 5. the device must not contain a ceph bluestore osd
# 6. the device must be larger than 5GB
#---------------------------------------------------------------------
sudo ceph orch device ls

#to attach devices at once
sudo ceph orch apply osd --all-availabel-devices --method raw


#-----------------------------------------------------------------------
#if you wish to prevent this behavior, you can use below command
# ceph orch apply osd --all-available-devices --unmanaged=true
#
#  manuallly create an osd from a specific device on a specifif host:
#  ceph orch daemon add osd <host>:<device-path>
#-----------------------------------------------------------------------

sudo orch device ls
sudo ceph -s
