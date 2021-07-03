#Create AMI in AWS with Ubuntu 16.04
#Install memcahce
apt update && sudo apt install memcached

#Download the latest libmemcached
wget https://launchpad.net/libmemcached/1.0/1.0.18/+download/libmemcached-1.0.18.tar.gz

#untar
tar -xvf libmemcached-1.0.18.tar.gz
cd libmemcached-1.0.18.tar.gz

#Install essetial packages
sudo apt-get install build-essential

#Install libevent-dev
sudo apt-get install libevent-dev

./configure --enable-memaslap

vim Makefile

# Edit Makefile by adding LDFLAGS "-L/lib64 -lpthread"
# https://bugs.launchpad.net/libmemcached/+bug/1562677
### diff of Makefile
# -LDFLAGS =
# +LDFLAGS = -L/lib64 -lpthread 
###

sudo make install

# Run memaslap 
./clients/memaslap -s 127.0.0.1:11211 -t 20s
