echo "---restart nova-api"
sudo systemctl restart nova-api
echo "-----restart nova-scheduler"
sudo systemctl restart nova-scheduler
echo "-------restart nova-conductor"
sudo systemctl restart nova-conductor
echo "--------restart nova-novncprox"
sudo systemctl restart nova-novncproxy
echo "---------------------------"
