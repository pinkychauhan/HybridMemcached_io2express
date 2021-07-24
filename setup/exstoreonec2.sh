#!/bin/bash
sudo su
yum -y update
cd /
mkdir storage
lsblk
mkfs.ext4 /dev/nvme1n1
mount /dev/nvme1n1 storage
chown ec2-user storage

cd /opt
sudo yum -y install '@Development Tools' openssl-devel libevent-devel
sudo wget https://memcached.org/latest -O memcached-latest.tar.gz --no-check-certificate
tar xvf memcached-latest.tar.gz
cd memcached-*/
sudo ./configure
sudo make
sudo make install

sudo tee /etc/sysconfig/memcached <<EOF
# These defaults will be used by every memcached instance, unless overridden
# by values in /etc/sysconfig/memcached.<port>
USER="ec2-user"
MAXCONN="65000"
CACHESIZE="13000"
OPTIONS="-o ext_path=/storage/datafile:90G -o hashpower=16 -v"
# The PORT variable will only be used by memcached.service, not by
# memcached@xxxxx services, which will use the xxxxx
PORT="11211"
EOF

#Create new Memcached Systemd unit file.
sudo vim /etc/systemd/system/memcached.service

#Paste below contents:

[Unit]
Description=memcached daemon
After=network.target

[Service]
EnvironmentFile=/etc/sysconfig/memcached
ExecStart=/usr/local/bin/memcached -p ${PORT} -u ${USER} -m ${CACHESIZE} -c ${MAXCONN} $OPTIONS
PrivateTmp=true
ProtectSystem=full
NoNewPrivileges=true
PrivateDevices=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

[Install]
WantedBy=multi-user.target


#Reload Systemd and start systemd
sudo systemctl daemon-reload
sudo systemctl start memcached
sudo systemctl status memcached


