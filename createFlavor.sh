source admin-openrc.sh
openstack flavor create --id 0 --vcpus 1 --ram 64 --disk 1 m1.nano
openstack flavor create --id 1 --vcpus 1 --ram 128 --disk 2 m1.small
openstack flavor create --id 2 --vcpus 1 --ram 256 --disk 3 m1.large
openstack flavor create --id 3 --vcpus 2 --ram 512 --disk 5 m1.xlarge
