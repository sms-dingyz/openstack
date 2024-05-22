

------------+--------------------------+--------------------------+------------
            |                          |                          |
    ens3f0|192.168.100.11    ens3f0|192.168.100.12        ens3f0|192.168.100.13
+-----------+-----------+  +-----------+-----------+  	+-----------+-----------+
|     [ controller ]    |  |       [ compute ]     |  	|       [ storage ]     |
|     (Control Node)    |  |      Nova-Compute     |  	|      Swift-Container  |
|     Cinder Volume     |  |     Cinder Volume     |  	|      Swift-Account    |
| MariaDB   RabbitMQ    |  |      Swift-Account    |  	|      Swift-Object     |
| Memcached Swift Proxy |  |    Swift-Container    |  	|                       |
| Keystone  httpd       |  |      Swift-Object     |  	|                       |
+-----------------------+  +-----------------------+  	+-----------------------+


-------------------------------------------------------------------------- 	
-------------------------------------------------------------------------- 	
controller、compute01、storage都是以stack用户登录系统
-------------------------------------------------------------------------- 
-------------------------------------------------------------------------- 	  
controller:

1. 修改root密码
stack@controller:~$ sudo passwd
New password:
Retype new password:
passwd: password updated successfully
--------------------------------------------------------------------------



2. 修改sshd_config文件
sudo vi /etc/ssh/sshd_config，把PermitRootLogin、PasswordAuthentication改为yes,保存文件。执行sudo systemctl restart sshd重启sshd服务
PermitRootLogin yes
PasswordAuthentication yes


--------------------------------------------------------------------------
3.增加账号权限(linux系统登录账号),测试服务器的登录账号是stack
3.1 sudo vi /etc/sudoers.d/stack
3.2 文件stack中添加 stack ALL=(ALL) NOPASSWD:ALL
3.3 保存stack文件

--------------------------------------------------------------------------

4. 修改hostname
4.1  sudo vi /etc/hostname
4.2  把hostname改为controller

--------------------------------------------------------------------------
5. 设置网络
5.1 sudo chmod 600 /etc/netplan/00-installer-config.yaml
5.2 sudo vi /etc/netplan/00-installer-config.yaml
5.3 文件00-installer-config.yaml内容如下，具体的ip可以用ip a查看，然后设置对应的ip就可以。
network:
  ethernets:
    eno5:
      addresses:
      - 10.183.13.201/24
      nameservers:
        addresses:
        - 8.8.8.8
        search: []
      routes:
      - to: default
        via: 10.183.13.1
    eno6:
      dhcp4: true
    ens1f1:
      dhcp4: true
    ens3f0:
      addresses:
      - 192.168.100.11/24
      nameservers:
        addresses: []
        search: []
    ens3f1:
      dhcp4: true
  version: 2
  
  5.4 修改00-installer-config.yaml后，使用sudo netplan apply 使其生效。
  5.5  验证网络是否正常，ping www.baidu.com
  
--------------------------------------------------------------------------
  6. 修改DNS
  
  6.1 参考文档https://www.baeldung.com/linux/permanent-etc-resolv-conf
  6.2 修改后的结果
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  options edns0 trust-ad
  search .
  
--------------------------------------------------------------------------
  7. 安装 ifupdown
  7.1 sudo apt install ifupdown
  7.2 sudo vi /etc/network/interfaces,interfaces添加如下内容（注意eno5是provider网络，可以用ip a查看，填写正确的provider网络)
  source /etc/network/interfaces.d/*
  auto eno5
  iface eno5 inet manual
  up ip link set dev $IFACE up
  down ip link set dev $IFACE down
  
 
-------------------------------------------------------------------------- 
  8. 修改hosts文件
  8.1 sudo vi  /etc/hosts,设置各个节点的ip，带有-api表示provider网络，否则表示management网络。根据实际的ip设置对应的值。
	#127.0.1.1 controller
	192.168.100.11  controller
	10.183.13.201   controller-api

	192.168.100.12  compute01
	10.183.13.202   compute01-api

	192.168.100.13  storage
	10.183.13.203   storage-api
	
	
-------------------------------------------------------------------------- 	
  10. 设置文件所有者
  10.1 sudo -i 切换到root 
  10.2 下载代码  git clone git@github.com:sms-dingyz/openstack.git
  10.3 进入openstack目录，cp * /stack/home/
  10.4 chown -R stack.stack *
  10.5 exit退出root
 
  
  
-------------------------------------------------------------------------- 
compute01节点配置 	
-------------------------------------------------------------------------- 		 
compute01:
1. 修改root密码
stack@controller:~$ sudo passwd
New password:
Retype new password:
passwd: password updated successfully
--------------------------------------------------------------------------



2. 修改sshd_config文件
sudo vi /etc/ssh/sshd_config，把PermitRootLogin、PasswordAuthentication改为yes,保存文件。执行sudo systemctl restart sshd重启sshd服务
PermitRootLogin yes
PasswordAuthentication yes


--------------------------------------------------------------------------
3.增加账号权限(linux系统登录账号),测试服务器的登录账号是stack
3.1 sudo vi /etc/sudoers.d/stack
3.2 文件stack中添加 stack ALL=(ALL) NOPASSWD:ALL
3.3 保存stack文件

--------------------------------------------------------------------------

4. 修改hostname
4.1  sudo vi /etc/hostname
4.2  把hostname改为compute01

--------------------------------------------------------------------------
5. 设置网络
5.1 sudo chmod 600 /etc/netplan/00-installer-config.yaml
5.2 sudo vi /etc/netplan/00-installer-config.yaml
5.3 文件00-installer-config.yaml内容如下，具体的ip可以用ip a查看，然后设置对应的ip就可以。
network:
  ethernets:
    eno5:
      dhcp4: false
      dhcp6: false
      addresses:
        - 10.183.13.202/24
      routes:
        - to: default
          via: 10.183.13.1
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
    eno6:
      dhcp4: true
    eno7:
      dhcp4: true
    eno8:
      dhcp4: true
    ens1f0:
      dhcp4: true
    ens1f1:
      dhcp4: true
    ens3f0:
      addresses:
        - 192.168.100.12/24
      dhcp4: false
      dhcp6: false
    ens3f1:
      dhcp4: true
  version: 2

  
  5.4 修改00-installer-config.yaml后，使用sudo netplan apply 使其生效。
  5.5  验证网络是否正常，ping www.baidu.com
  
--------------------------------------------------------------------------
  6. 修改DNS
  6.1  cd /etc
  6.2 sudo vi resolv.conf,添加nameserver
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  options edns0 trust-ad
  search .

-------------------------------------------------------------------------- 
  7. 修改hosts文件
  7.1 sudo vi  /etc/hosts,设置各个节点的ip，带有-api表示provider网络，否则表示management网络。根据实际的ip设置对应的值。
	#127.0.1.1 controller
	192.168.100.11  controller
	10.183.13.201   controller-api

	192.168.100.12  compute01
	10.183.13.202   compute01-api

	192.168.100.13  storage
	10.183.13.203   storage-api
	
-------------------------------------------------------------------------- 	
storage节点配置 	
-------------------------------------------------------------------------- 	
storage:
1. 修改root密码
stack@controller:~$ sudo passwd
New password:
Retype new password:
passwd: password updated successfully
--------------------------------------------------------------------------



2. 修改sshd_config文件
sudo vi /etc/ssh/sshd_config，把PermitRootLogin、PasswordAuthentication改为yes,保存文件。执行sudo systemctl restart sshd重启sshd服务
PermitRootLogin yes
PasswordAuthentication yes


--------------------------------------------------------------------------
3.增加账号权限(linux系统登录账号),测试服务器的登录账号是stack
3.1 sudo vi /etc/sudoers.d/stack
3.2 文件stack中添加 stack ALL=(ALL) NOPASSWD:ALL
3.3 保存stack文件

--------------------------------------------------------------------------

4. 修改hostname
4.1  sudo vi /etc/hostname
4.2  把hostname改为storage

--------------------------------------------------------------------------
5. 设置网络
5.1 sudo chmod 600 /etc/netplan/00-installer-config.yaml
5.2 sudo vi /etc/netplan/00-installer-config.yaml
5.3 文件00-installer-config.yaml内容如下，具体的ip可以用ip a查看，然后设置对应的ip就可以。
network:
  ethernets:
    eno5:
      dhcp4: false
      dhcp6: false
      addresses:
        - 10.183.13.203/24
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
      routes:
        - to: default
          via: 10.183.13.1
    eno6:
      dhcp4: true
    ens3f0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.100.13/24
    ens3f1:
      dhcp4: true
  version: 2

  
  5.4 修改00-installer-config.yaml后，使用sudo netplan apply 使其生效。
  5.5  验证网络是否正常，ping www.baidu.com
  
--------------------------------------------------------------------------
  6. 修改DNS
  6.1  cd /etc
  6.2 sudo vi resolv.conf,添加nameserver
  nameserver 8.8.8.8
  nameserver 8.8.4.4
  options edns0 trust-ad
  search .


-------------------------------------------------------------------------- 
  7. 修改hosts文件
  7.1 sudo vi  /etc/hosts,设置各个节点的ip，带有-api表示provider网络，否则表示management网络。根据实际的ip设置对应的值。
	#127.0.1.1 controller
	192.168.100.11  controller
	10.183.13.201   controller-api

	192.168.100.12  compute01
	10.183.13.202   compute01-api

	192.168.100.13  storage
	10.183.13.203   storage-api
	
	
	
	


-------------------------------------------------------------------------- 	
ssh配置 	
-------------------------------------------------------------------------- 	
  1. 确保controller、compute01、storage之间可以互相ping通(stack和root都能互相ping通)
  1.1 controller：	ping compute01   ping  storage
  1.2 compute01： 	ping controller  ping  storage
  1.3 storage：   	ping controller  ping  compute01
  

  2. controller
  2.1 stack用户，使用ssh-keygen -P ""生成 stack key pair
  2.2 输入命令ssh-copy-id controller拷贝stack key.根据提示操作，选择yes就可以。
  2.3 输入命令ssh-copy-id compute01 拷贝stack key.根据提示操作，选择yes就可以。
  2.4 输入命令ssh-copy-id storage 拷贝stack key.根据提示操作，选择yes就可以。
  2.5 sudo -s 进入root用户
  2.6 ssh-keygen -P ""生成root key
  2.7 输入命令ssh-copy-id controller拷贝root key.根据提示操作，选择yes就可以。
  2.8 输入命令ssh-copy-id compute01 拷贝root key.根据提示操作，选择yes就可以。
  2.9 输入命令ssh-copy-id storage 拷贝root key.根据提示操作，选择yes就可以。
  
  
  
  3. compute01
  
	stack
  3.1 stack 用户，使用ssh-keygen -P ""生成 stack key pair
  3.2 输入命令ssh-copy-id compute01 拷贝stack key.根据提示操作，选择yes就可以。
  3.3 输入命令ssh-copy-id controller 拷贝stack key.根据提示操作，选择yes就可以。
  3.4 输入命令ssh-copy-id storage 拷贝stack key.根据提示操作，选择yes就可以。
  
	root
  3.5 sudo -s 进入root用户
  3.6 ssh-keygen -P ""生成root key
  3.7 输入命令ssh-copy-id compute01拷贝root key.根据提示操作，选择yes就可以。
  3.8 输入命令ssh-copy-id controller 拷贝root key.根据提示操作，选择yes就可以。
  3.9 输入命令ssh-copy-id storage 拷贝root key.根据提示操作，选择yes就可以。
  
  
   
  4. storage
  
     stack:
  4.1 stack 用户，使用ssh-keygen -P ""生成 stack key pair
  4.2 输入命令ssh-copy-id storage拷贝stack key.根据提示操作，选择yes就可以。
  4.3 输入命令ssh-copy-id controller 拷贝stack key.根据提示操作，选择yes就可以。
  4.4 输入命令ssh-copy-id compute01 拷贝stack key.根据提示操作，选择yes就可以。
  
	 root:
  4.5 sudo -s 进入root用户
  4.6 ssh-keygen -P ""生成root key
  4.7 输入命令ssh-copy-id storage拷贝root key.根据提示操作，选择yes就可以。
  4.8 输入命令ssh-copy-id controller 拷贝root key.根据提示操作，选择yes就可以。
  4.9 输入命令ssh-copy-id compute01 拷贝root key.根据提示操作，选择yes就可以。
  
  
  
-------------------------------------------------------------------------- 	
设置文件所有者	
-------------------------------------------------------------------------- 	
  controller
  1. 拷贝执行脚本到/stack/home目录
  2. sudo -i
  3. chown -R stack.stack *
  4. exit退出root
  
  
 compute01
  1. 拷贝执行脚本到/stack/home目录
  2. sudo -i
  3. chown -R stack.stack *
  4. exit退出root
  
  
   storage
  1. 拷贝执行脚本到/stack/home目录
  2. sudo -i
  3. chown -R stack.stack *
  4. exit退出root
  


--------------------------------------------------------------------------
openstack版本
--------------------------------------------------------------------------
controller
1. vi /home/stack/config/openstack修改版本
: ${OPENSTACK_RELEASE:=zed}
2.目前测试通过版本为zed，后续可以验证bobcat。




  
-------------------------------------------------------------------------- 	
下载image
-------------------------------------------------------------------------- 	
controller
1. cd /home/stack/scripts
2. ./pre-download.sh




  
-------------------------------------------------------------------------- 	
脚本执行	
-------------------------------------------------------------------------- 	
controller
1. cd /home/stack/scripts/ubuntu

Execute the scriptes in the given order:
-------------------------------------------------------------------------------
stack@controller:~/scripts/ubuntu$ ./1_controller_apt_init.sh
stack@controller:~/scripts/ubuntu$ ./2_controller_apt_upgrade

stack@controller:~/scripts/ubuntu$ ./3_controller_install_mysql.sh
stack@controller:~/scripts/ubuntu$ ./4_controller_install_rabbitmq.sh
stack@controller:~/scripts/ubuntu$ ./5_controller_install_memcached.sh

stack@controller:~/scripts/ubuntu$ ./6_controller_setup_keystone_1.sh
stack@controller:~/scripts/ubuntu$ ./7_controller_setup_keystone_2.sh

stack@controller:~/scripts/ubuntu$ ./8_controller_setup_glance_1.sh
stack@controller:~/scripts/ubuntu$ ./9_controller_setup_glance_2.s

stack@controller:~/scripts/ubuntu$ ./10_controller_setup_placement_1.sh
stack@controller:~/scripts/ubuntu$ ./11_controller_setup_placement_2.sh

stack@controller:~/scripts/ubuntu$ ./12_controller_setup_nova_1.sh
stack@controller:~/scripts/ubuntu$ ./13_controller_setup_nova_2.sh
stack@controller:~/scripts/ubuntu$ ./14_controller_setup_nova_3.sh

stack@controller:~/scripts/ubuntu$ ./16_controller_setup_neutron_1.sh
stack@controller:~/scripts/ubuntu$ ./17_controller_setup_neutron_2.sh
stack@controller:~/scripts/ubuntu$ ./18_controller_setup_neutron_3.sh
stack@controller:~/scripts/ubuntu$ ./19_controller_setup_neutron_4.sh

stack@controller:~/scripts/ubuntu$ ./20_controller_setup_horizon.sh

stack@controller:~/scripts/ubuntu$ ./21_controller_setup_cinder_1.sh
stack@controller:~/scripts/ubuntu$ ./22_controller_setup_cinder_2.sh
 
-------------------------------------------------------------------------------

stack@controller:~/scripts/ubuntu$ ./27_controller_setup_swift_1.sh
stack@controller:~/scripts/ubuntu$ ./28_controller_setup_swift_2.sh

 
-------------------------------------------------------------------------------
//very importance Don't Execute the script 29_controller_setup_swift_3.sh  now.  it will 
be executed after finishing installation of  storage node
-------------------------------------------------------------------------------
stack@controller:~/scripts/ubuntu$ ./29_controller_setup_swift_3.sh



check whether swift works correctly by making a container and placing an object in it. 
Do the following on the controller node:
cd /home/stack
source demo-openrc.sh
swift stat

-------------------------------------------------------------------------------
swift works correctly when show following messages after executing swift stat
-------------------------------------------------------------------------------
Account: AUTH_33569bb56110474db2d584b4a1936c6b
Containers: 0
Objects: 0
Bytes: 0
Content-Type: text/plain; charset=utf-8
X-Timestamp: 1580951741.32857
X-Put-Timestamp: 1580951741.32857
X-Trans-Id: tx0dec10331bb941488a804-005e3b68bc
X-Openstack-Request-Id: tx0dec10331bb941488a804-005e3b68bc





-------------------------------------------------------------------------------
On contoller Node, create instance.
-------------------------------------------------------------------------------
1 cd /home/stack
2 ./createProvider.sh
3 ./createFlavor.sh
4 ./createSecurityGroup.sh 






-------------------------------------------------------------------------------
On Compute Node, execute the scripts in  the following order.
-------------------------------------------------------------------------------
stack@compute:~/scripts/ubuntu$ ./1_compute_apt_init.sh
stack@compute:~/scripts/ubuntu$ ./2_compute_apt_upgrade.sh

stack@compute:~/scripts/ubuntu$ ./3_compute_setup_nova_1.sh
stack@compute:~/scripts/ubuntu$ ./4_compute_setup_nova_2.sh

stack@compute:~/scripts/ubuntu$ ./5_compute_setup_neutron_1.sh
stack@compute:~/scripts/ubuntu$ ./6_compute_setup_neutron_2.sh
stack@compute:~/scripts/ubuntu$ ./7_compute_setup_neutron_3.sh
stack@compute:~/scripts/ubuntu$ ./8_compute_setup_neutron_4.sh

stack@compute:~/scripts/ubuntu$ ./9_compute_setup_cinder_1.sh
stack@compute:~/scripts/ubuntu$ ./10_compute_setup_cinder_2.sh

stack@compute:~/scripts/ubuntu$ ./11_compute_setup_swift_1.sh
stack@compute:~/scripts/ubuntu$ ./12_compute_setup_swift_2.sh
stack@compute:~/scripts/ubuntu$ ./13_compute_setup_swift_3.sh


-------------------------------------------------------------------------------
One Storage Node, execute the scripts in  the following order.
-------------------------------------------------------------------------------
stack@storage:~/scripts/ubuntu$ ./1_storage_apt_init.sh

stack@storage:~/scripts/ubuntu$ ./2_storage_setup_swift_1.sh
stack@storage:~/scripts/ubuntu$ ./3_storage_setup_swift_2.sh
stack@storage:~/scripts/ubuntu$ ./4_storage_setup_swift_3.sh


-------------------------------------------------------------------------------
Back to controller node, execute the following script
-------------------------------------------------------------------------------

stack@controller:~/scripts/ubuntu$ ./29_controller_setup_swift_3.sh

-------------------------------------------------------------------------------
Create public network, private network and router
-------------------------------------------------------------------------------
stack@controller:~/scripts/ubuntu$ cd ..
stack@controller:~/scripts$ ./config_public_network.sh
stack@controller:~/scripts$ ./config_private_network.sh





安装过程中的问题解决:
controller:

1.install glance
INFO glance.async_ [-] Threadpool model set to 'EventletThreadPoolModel'
ERROR stevedore.extension [-] Could not load 'glance.store.s3.Store': No module named 'boto3': ModuleNotFoundError: No module named 'boto3'
ERROR stevedore.extension [-] Could not load 's3': No module named 'boto3': ModuleNotFoundError: No module named 'boto3'

solution:
sudo apt install python3-pip
sudo pip3 install boto3

2.install keystone or cinder
Failed to restart libvirtd.service: Unit virtlogd.socket is masked

solution:
sudo systemctl unmask virtlogd.socket
sudo systemctl restart libvirtd

check libvirtd status
sudo systemctl status libvirtd  

如果报以下错误
stack@compute01:/etc$ sudo systemctl status libvirtd
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-03-21 03:53:08 UTC; 1 week 0 days ago
TriggeredBy: ● libvirtd-ro.socket
             ● libvirtd.socket
             ● libvirtd-admin.socket
       Docs: man:libvirtd(8)
             https://libvirt.org
   Main PID: 2339 (libvirtd)
      Tasks: 21 (limit: 32768)
     Memory: 78.8M
        CPU: 24min 29.332s
     CGroup: /system.slice/libvirtd.service
             ├─2339 /usr/sbin/libvirtd
             ├─2567 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/lib/libvirt/libvirt_leaseshelper
             └─2568 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/lib/libvirt/libvirt_leaseshelper

Mar 28 06:45:01 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mips64' architecture is not supported by CPU driver
Mar 28 06:45:01 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mips64el' architecture is not supported by CPU driver
Mar 28 06:45:01 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'ppc' architecture is not supported by CPU driver
Mar 28 06:45:02 compute01 libvirtd[2339]: End of file while reading data: Input/output error
Mar 28 06:45:36 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mips' architecture is not supported by CPU driver
Mar 28 06:45:36 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mipsel' architecture is not supported by CPU driver
Mar 28 06:45:36 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mips64' architecture is not supported by CPU driver
Mar 28 06:45:36 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'mips64el' architecture is not supported by CPU driver
Mar 28 06:45:36 compute01 libvirtd[2339]: this function is not supported by the connection driver: 'ppc' architecture is not supported by CPU driver
Mar 28 06:45:36 compute01 libvirtd[2339]: End of file while reading data: Input/output error

修改文件 /var/lib/libvirt/dnsmasq/default.conf 把dhcp-range修改为实际的ip范围

#dhcp-range=192.168.122.2,192.168.122.254,255.255.255.0
dhcp-range=192.168.100.11,192.168.100.254,255.255.255.0




如果报以下错误：
stack@controller:~$ sudo systemctl status libvirtd
● libvirtd.service - Virtualization daemon
     Loaded: loaded (/lib/systemd/system/libvirtd.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2024-04-02 02:06:38 UTC; 6min ago
TriggeredBy: ○ libvirtd-ro.socket
             ○ libvirtd-admin.socket
             ○ libvirtd.socket
       Docs: man:libvirtd(8)
             https://libvirt.org
   Main PID: 26125 (libvirtd)
      Tasks: 19 (limit: 32768)
     Memory: 12.6M
        CPU: 3.927s
     CGroup: /system.slice/libvirtd.service
             └─26125 /usr/sbin/libvirtd

Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-ppc64le' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-riscv32' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-riscv64' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-s390x' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-sh4' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-sh4eb' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-sparc' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-sparc64' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-xtensa' on this host
Apr 02 02:07:50 controller libvirtd[26125]: invalid argument: KVM is not supported by '/usr/bin/qemu-system-xtensaeb' on this host


解决方案:
sudo vim /etc/nova/nova-compute.conf
virt_type=kvm
sudo systemctl restart libvirtd
sudo systemctl restart nova-compute
cd /home/stack
./novaServicesUp.sh 



重新启动服务
sudo systemctl restart libvirtd
sudo systemctl restart apache2


Note:
这个阶段严格检查libvirtd、nova、neutron的状态,如果状态有错，应该仔细检查解决，保证状态正常。
sudo systemctl status libvirtd
sudo systemctl status nova-api
sudo systemctl status nova-scheduler
sudo systemctl status nova-conductor
sudo systemctl status nova-novncproxy

sudo systemctl status neutron-server
sudo systemctl status neutron-linuxbridge-agent
sudo systemctl status neutron-dhcp-agent
sudo systemctl status neutron-metadata-agent





3.dashboard创建实例报错：
Build of instance  aborted: Unable to update attachment.(Bad or unexpected response from the storage volume backend API
https://blog.csdn.net/yjp19871013/article/details/120282617

controller:

sudo vi /etc/lib/tgt/targets.conf
添加
include /var/lib/cinder/volumes/*

sudo systemctl restart tgt
sudo systemctl restart cinder-volume.service




3.apache2出现wsgi的错误
需要在apache的模块里添加wsgi

sudo vi /etc/apache2/mods-available/wsgi.load 添加
LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so

保存后执行sudo a2enmod wsgi

如果提示没有wsgi,则需要加载
sudo apt-get install libapache2-mod-wsgi
再次执行sudo a2enmod wsgi

sudo systemctl restart apache2


sudo vi /etc/apache2/apache2.conf增加ServerName controller


sudo systemctl restart apache2


4.如果安装到14_controller_setup_nova_3.sh 报错Failed to restart libvirtd.service nova-compute 启动失败。需要把服务重启
sudo systemctl status nova-compute
sudo systemctl restart nova-compute
cd /home/stack
./ novaServicesUp.sh
重新执行14_controller_setup_nova_3.sh


如果sudo systemctl status libvirtd.service出现
internal error: firewalld is set to use the nftables backend

解决方法：

尝试重新启动firewalld服务：systemctl restart firewalld。

如果问题依旧，尝试重置firewalld的配置：firewall-cmd --reload。

检查是否有其他服务或配置与nftables冲突。

如果上述步骤无效，可以尝试将firewalld配置为使用iptables后端，而不是nftables：

编辑firewalld的配置文件（例如/etc/firewalld/firewalld.conf），将#FirewallBackend=nftables改为FirewallBackend=iptables，并去掉行首的注释符号


5. 如果执行20_controller_setup_horizon.sh后无法登录dashboard,出现ERROR django.request Internal Server Error: /horizon/auth/login/
sudo  apt remove -y --purge openstack-dashboard
sudo apt install openstack-dashboard
sudo systemctl restart apache2


6.查看instance log
/var/lib/nova/instances






7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）



7. 如何手动删除孤儿网络端口
openstack port list (查看端口列表）

+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| ID                                   | Name       | MAC Address       | Fixed IP Addresses                                                           | Status |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+
| 62532dbe-992b-4e82-aa40-9abe8de83dbb |            | fa:16:3e:b3:d2:1d | ip_address='10.183.13.232', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6c51143f-5b1f-404c-bcc4-3d2f1cdf6cd3 |            | fa:16:3e:59:f4:c3 | ip_address='10.183.13.243', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 6cf7ab2d-1346-4137-8938-9afd8c2779c0 |            | fa:16:3e:f2:08:93 | ip_address='10.183.13.206', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 8f51972e-6a13-4b58-8431-1deeed30a776 |            | fa:16:3e:66:31:79 | ip_address='10.183.13.211', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| 9eec0b9b-a880-47d0-a679-c2110e81aca0 |            | fa:16:3e:b3:5f:ec | ip_address='10.183.13.201', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| a285243a-8d68-4022-af4a-05dbd0b16bee |            | fa:16:3e:0d:2a:af | ip_address='10.183.13.213', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | ACTIVE |
| feecee90-0cbe-4d8b-8730-e34a0f36b619 | fixed-port | fa:16:3e:a0:85:2a | ip_address='10.183.13.205', subnet_id='f92fed3a-11dc-4f9d-aa65-24d7af09d5a7' | DOWN   |
+--------------------------------------+------------+-------------------+------------------------------------------------------------------------------+--------+

sudo mysql （终端cmd进入mysql数据库)
use neutron;(切换数据表）
delete ports from where id='feecee90-0cbe-4d8b-8730-e34a0f36b619';(删除指定端口feecee90-0cbe-4d8b-8730-e34a0f36b619）


8. how to resize instance
sudo vi /etc/nova/nova.conf

allow_resize_to_same_host = true
allow_migrate_to_same_host = true
scheduler_default_filters = AllHostsFilter

