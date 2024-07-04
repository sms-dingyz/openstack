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

# Use repository redirection for faster repository access.
# instead of the 'us.archive.ubuntu.com' ones in United States
sudo sed  -i 's/mirrors.aliyun.com/archive.ubuntu.com/g' /etc/apt/sources.list

# Get apt index files
echo " apt updating...."
sudo apt update

echo " apt upgrading..."
sudo apt upgrade

# Disable automatic updates
sudo systemctl disable apt-daily.service
sudo systemctl disable apt-daily.timer

# ---------------------------------------------------------------------------
# Install chrony
# ---------------------------------------------------------------------------
echo " installing chrony....."
sudo apt install chrony -y

# ---------------------------------------------------------------------------
# edit the chrony configuration and set your ntp server by replacing the ntp 
# server pools with you ntp server address
# ---------------------------------------------------------------------------
sudo sed -i 's/pool\ ntp.ubuntu.com/\#pool\ ntp.ubuntu.com/g' /etc/chrony/chrony.conf
sudo sed -i 's/pool\ 0.ubuntu.pool/\#pool\ 0.ubuntu.pool/g' /etc/chrony/chrony.conf
sudo sed -i 's/pool\ 1.ubuntu.pool/\#pool\ 1.ubuntu.pool/g' /etc/chrony/chrony.conf
sudo sed -i 's/pool\ 2.ubuntu.pool/\#pool\ 2.ubuntu.pool/g' /etc/chrony/chrony.conf
sudo sed -i '/maxsources\ 2/a pool net.kifarunix-com-demo.com iburst' /etc/chrony/chrony.conf

# ---------------------------------------------------------------------------
# restart chrony
# ---------------------------------------------------------------------------
echo "restart chrony...."
sudo systemctl restart chrony

# ---------------------------------------------------------------------------
# install openssh-server
# ---------------------------------------------------------------------------
echo "installing openssh-server"
sudo apt install openssh-server
sudo systemctl enable --now ssh


# ---------------------------------------------------------------------------
#enable root login on other nodes from ceph admin node
# ---------------------------------------------------------------------------
sudo sed -i 's/\#PermitRootLogin\ probit-password/PermitRootLogin\ yes/g' /etc/ssh/ssh_config
sudo sed -i 's/\#PasswordAuthentication\ no/PasswordAthentication\ yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd

#set user stack
sudo sed -i '1 i\'$USER' ALL=(root) NOPASSWD:ALL' /etc/sudoers.d/$USER 

