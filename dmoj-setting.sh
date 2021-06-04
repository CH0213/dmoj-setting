#!/bin/bash



# Please run it before you run the script.
# 1. sudo passwd
# 2. su
# 3. echo 'kch ALL=NOPASSWD: ALL' >> /etc/sudoers
#            ┗ 자신의 계정명
# 4. exit

# Please run it after you run the script.
# 1. su
# 2. sed '$ d' /etc/sudoers -i
# 3. exit

## Installing the prerequisites
echo "======================Installing the prerequisites======================"
sudo apt-get update
sudo apt-get install -y git gcc g++ make python3-dev python3-pip libxml2-dev libxslt1-dev zlib1g-dev gettext curl redis-server
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g sass postcss-cli postcss autoprefixer
