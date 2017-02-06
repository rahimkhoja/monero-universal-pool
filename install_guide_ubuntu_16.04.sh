#!/usr/bin/env bash
# Monero Pool Install Script
# By: Rahim Khoja ( rahim@khoja.ca )
#
# Based on zone117x node-cryptonote-pool & fancoder cryptonote-universal-pool
# https://github.com/fancoder/cryptonote-universal-pool 
# https://github.com/zone117x/node-cryptonote-pool
#
# Requires Ubuntu 16.04
# Installs Node 0.10.48 64-Bit & Redis
#

# System Updates and Pool Requirements
yes | sudo apt-get -y --force-yes update
yes | sudo apt-get -y --force-yes upgrade
sudo apt-get install git libssl-dev libboost-all-dev build-essential tcl curl gcc g++ cmake

# Install Redis
cd /tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable
make
make test
sudo make install
sudo mkdir /etc/redis
sudo cp /tmp/redis-stable/redis.conf /etc/redis
sudo adduser --system --group --no-create-home redis
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis

# Update Redis Files
# Change line that starts with "supervised no" to "supervised systemd"
sudo sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf
# Change line that starts with "dir ./"  to "dir /var/lib/redis"
sudo sed -i 's/dir .\//dir \/var\/lib\/redis/g' /etc/redis/redis.conf

# Install Node 0.10.48
cd /tmp
curl -O https://nodejs.org/download/release/v0.10.48/node-v0.10.48-linux-x64.tar.gz
tar xzvf node-v0.10.48-linux-x64.tar.gz
sudo cp /tmp/node-v0.10.48-linux-x64/bin/node /usr/bin/
sudo cp -R /tmp/node-v0.10.48-linux-x64/lib/* /usr/lib/
sudo ln -s /usr/lib/node_modules/npm/bin/npm-cli.js /usr/bin/npm

# Install Pool
cd /tmp
git clone https://github.com/CanadianRepublican/monero-universal-pool.git pool
sudo mv ./pool /opt/pool
cd /opt/pool
npm update

# Firewall Setup
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 3333
sudo ufw allow 5555
sudo ufw allow 7777
sudo ufw allow 8888

// The config file will need some configuring to work
cp ./config_example.json ./config.json

sudo cp ./utils/redis.service /etc/systemd/system/redis.service
sudo systemctl start redis
sudo systemctl enable redis

// run the pool
node init.js
