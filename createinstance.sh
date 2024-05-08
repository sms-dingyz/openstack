source demo-openrc.sh

openstack security group list
openstack network list

openstack server create --flavor m1.nano --image cirros --nic net-id=f6b16e86-4f45-468c-8b80-225a39347742 \
 --security-group default --key-name mykey myfirstinstance --debug

#openstack server show myfirstinstance

