sudo systemctl restart nova-api
sudo systemctl restart neutron-server
sudo systemctl restart neutron-linuxbridge-agent
sudo systemctl restart neutron-dhcp-agent
sudo systemctl restart neutron-metadata-agent
echo "--------------------------------"
sudo systemctl status neutron-server
sudo systemctl status neutron-linuxbridge-agent
sudo systemctl status neutron-dhcp-agent
sudo systemctl status neutron-metadata-agent

