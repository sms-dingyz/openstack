#!/usr/bin/env bash
nmcli radio wifi on
sudo sed  -i 's/deb\ \[trusted=yes/\#deb\ \[trusted=yes/g' /etc/apt/sources.list
sudo sed  -i 's/\#\#deb\ \[trusted=yes/\#deb\ \[trusted=yes/g' /etc/apt/sources.list
sudo sed  -i 's/#deb\ http:/deb\ http:/g' /etc/apt/sources.list
#https
sudo sed  -i 's/#deb\ https:/deb\ https:/g' /etc/apt/sources.list

#sudo sed  -i 's/#deb\ https:/deb\ https:/g' /etc/apt/sources.list.d/original.list



#sudo sed  -i 's/deb\ \[trusted=yes/\#deb\ \[trusted=yes/g' /etc/apt/sources.list.d/cloudarchive-zed.list
#sudo sed  -i 's/\#\#deb\ \[trusted=yes/\#deb\ \[trusted=yes/g' /etc/apt/sources.list.d/cloudarchive-zed.list
sudo sed  -i 's/\#deb\ \http/deb\ \http/g' /etc/apt/sources.list.d/cloudarchive-zed.list
