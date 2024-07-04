#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/openstack"
source "$CONFIG_DIR/localrc"
source "$LIB_DIR/functions.guest.sh"

indicate_current_auto

exec_logfile

set_apt_proxy


# ---------------------------------------------------------------------------
#  remove old version docker
# ---------------------------------------------------------------------------
sudo apt-get remove docker docker-engine docker.io containerd runc

# ---------------------------------------------------------------------------
# install docker dependency
# ---------------------------------------------------------------------------
echo " installing docker dependency...."
sudo apt-get install ca-certificates curl gnupg lsb-release


# ---------------------------------------------------------------------------
# add GPG of docker
# ---------------------------------------------------------------------------
sudo curl -fsSl https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -

# ---------------------------------------------------------------------------
# add docker repository
# ---------------------------------------------------------------------------
sudo add-apt-repository "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"

# ---------------------------------------------------------------------------
# install docker
# ---------------------------------------------------------------------------
sudo apt-get install docker-ce docker-ce-cli containerd.io


# ---------------------------------------------------------------------------
#  add user to docker group
# ---------------------------------------------------------------------------
sudo usermod -aG docker $USER

echo "starting  docker...."
sudo systemctl start docker

sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

echo " restarting docker service..."
sudo systemctl restart docker


echo "checking docker version...."
sudo docker version


# ---------------------------------------------------------------------------
# install lvm2
# ---------------------------------------------------------------------------
echo " installing lvm2 ..."
sudo apt install lvm2 -y
