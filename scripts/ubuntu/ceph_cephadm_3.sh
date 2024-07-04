#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto

exec_logfile

function set_apt_proxy {
    local PRX_KEY="Acquire::http::Proxy"
    local APT_FILE=/etc/apt/apt.conf

    if [ -f $APT_FILE ] && grep -q $PRX_KEY $APT_FILE; then
        # apt proxy has already been set (by preseed/kickstart)
        if [ -n "${VM_PROXY-}" ]; then
            # Replace with requested proxy
            sudo sed -i "s#^\($PRX_KEY\).*#\1 \"$VM_PROXY\";#" $APT_FILE
        else
            # No proxy requested -- remove
            sudo sed -i "s#^$PRX_KEY.*##" $APT_FILE
        fi
    elif [ -n "${VM_PROXY-}" ]; then
        # Proxy requested, but none configured: add line
        echo "$PRX_KEY \"$VM_PROXY\";" | sudo tee -a $APT_FILE
    fi
}

set_apt_proxy

sudo apt update


# Disable automatic updates
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer

#wget -q -O- 'https://download.ceph.com/keys/release.asc' |sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/cephadm.gpg

# Add cephadm repo
cat << EOF | sudo tee /etc/apt/sources.list.d/ceph.list
deb [arch=amd64] https://download.ceph.com/debian-18.2.2/ jammy main
#deb [arch=amd64]  https://download.ceph.com/$(lsb_release -sc)/ jammy main
EOF

# Import key required for cephadm 
sudo apt-key adv --fetch-keys 'https://download.ceph.com/keys/release.asc' 

# Update apt database for cephadm repo
sudo apt update \
    -o Dir::Etc::sourcelist="sources.list.d/ceph.list" \
    -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"


#install cephadm
echo "installing cephadm...."
sudo apt install cephadm

#synchronize time
echo "installing ntp ntpdate"
sudo apt install ntp ntpdate


sudo apt install ceph-common
#-----------------------------------------------------------------------------------
#now bootstrap the ceph cluster in order to create the firest ceph monitor daemon
#on  ceph admin node (ip : 192.168.100.170). you can substitute the ip address with
#that of the ceph admin node accordingly
#-----------------------------------------------------------------------------------

sudo cephadm bootstrap --mon-ip 192.168.100.170
sudo ceph -s


#-------------------------------------------------------------------------------------
# now we cant list all the hosts known to the Ceph orchestrator
#--------------------------------------------------------------------------------
sudo ceph orch host ls

