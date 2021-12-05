#!/usr/bin/env bash
#####################################################
# Created by cryptopool.builders for crypto use...
#####################################################

source /etc/functions.sh
source /etc/multipool.conf
source $STORAGE_ROOT/nomp/.nomp.conf

echo -e " Installing Redis...$COL_RESET"
apt_install build-essential tcl

cd $STORAGE_ROOT/nomp/nomp_setup/tmp
hide_output curl -O http://download.redis.io/redis-stable.tar.gz
hide_output tar xzvf redis-stable.tar.gz
cd redis-stable
hide_output make
hide_output sudo make install
sudo mkdir -p /etc/redis
sudo cp -r $STORAGE_ROOT/nomp/nomp_setup/tmp/redis-stable/redis.conf /etc/redis

sudo sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
sudo sed -i 's|dir ./|dir /var/lib/redis|g' /etc/redis/redis.conf

echo '
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target
' | sudo -E tee /etc/systemd/system/redis.service >/dev/null 2>&1

hide_output sudo adduser --system --group --no-create-home redis
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis
sudo systemctl start redis > /dev/null 2>&1
sudo systemctl enable redis > /dev/null 2>&1

echo -e "$GREEN Database build complete...$COL_RESET"

cd $HOME/multipool/nomp
