source admin-openrc.sh

openstack network create --share --provider-physical-network provider \
  --provider-network-type flat provider

openstack subnet create --network provider --allocation-pool start=10.183.13.201,end=10.183.13.250 --dns-nameserver 8.8.8.8 --gateway 10.183.13.1 --subnet-range 10.183.13.0/24 provider

openstack network list
