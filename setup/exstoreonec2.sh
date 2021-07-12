sudo su
yum -y update

cd /
mkdir storage
lsblk
mkfs.ext4 /dev/nvme1n1
mount /dev/nvme1n1 storage

chown ec2-user storage

cd /opt

#Install build dependencies using yum commands below
sudo yum -y install '@Development Tools' openssl-devel libevent-devel

#Download the latest Memcached release source code.
sudo wget https://memcached.org/latest -O memcached-latest.tar.gz

#Once the file is downloaded extract it with tar command line tool.
tar xvf memcached-latest.tar.gz

cd memcached-*/

#Run configuration command (Extstore built by default in 1.6.0 and higher)
sudo ./configure
sudo make
sudo make install

#Configure Systemd service file
#Create Memcached systemd environment configuration file:
#We can customize memory/exstore config here
sudo tee /etc/sysconfig/memcached <<EOF
# These defaults will be used by every memcached instance, unless overridden
# by values in /etc/sysconfig/memcached.<port>
USER="ec2-user"
MAXCONN="65000"
CACHESIZE="13000"
OPTIONS="-o ext_path=/storage/datafile:25G"
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


