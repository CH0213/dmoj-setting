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

## Creating the database
echo "======================Creating the database========================="
sudo apt-get update
sudo apt-get install -y mariadb-server libmysqlclient-dev
sudo mysql -e "CREATE DATABASE dmoj DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_general_ci"
sudo mysql -e "GRANT ALL PRIVILEGES ON dmoj.* to 'dmoj'@'localhost' IDENTIFIED BY '1234'" # 비밀번호를 설정하세요. ex) 1234

## Installing prerequisites
echo "======================Installing prerequisites========================="
sudo apt-get install -y python3-venv
python3 -m venv dmojsite
. dmojsite/bin/activate

git clone https://github.com/DMOJ/site.git
cd site
git checkout v2.1.0  # only if planning to install a judge from PyPI, otherwise skip this step
git submodule init
git submodule update

cd dmoj
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/local_settings.py
sed -i 's/<password>/1234/g' local_settings.py # 비밀번호를 설정하세요. ex) 1234
echo "Setting the password for [local_settings.py]"
sed -i 's/#CELERY_BROKER_URL/CELERY_BROKER_URL/g' local_settings.py
echo "Setting the CELERY_BROKER_URL for [local_settings.py]"
sed -i 's/#CELERY_RESULT_BACKEND/CELERY_RESULT_BACKEND/g' local_settings.py
echo "Setting the CELERY_RESULT_BACKEND for [local_settings.py]"
cd ..

pip install wheel
pip3 install -r requirements.txt
pip3 install mysqlclient