#!/usr/bin/env bash

#Note: current test account is stack. if you use different account (for example xxx) . you must use xxx replace stack in this script

#add local path to apt sources
sudo sed  -i '1 i\deb [trusted=yes] file:/opt/local/debs ./' /etc/apt/sources.list

#permit and auth
sudo sed  -i 's/\#\PasswordAuthentication\ no/PasswordAuthentication\ yes/g' /etc/ssh/sshd_config
sudo sed  -i 's/\#\PermitRootLogin\ prohibit-password/PermitRootLogin\ yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
echo "stack ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/stack 

#change root password  format:password:name
sudo echo -e "stack:stack" | sudo chpasswd 

cd /hom/stack
sudo -i
chown -R stack.stack *

#sudo sed  -i '1 i\stack ALL=(ALL) NOPASSWD:ALL' /etc/sudoers.d/stack

