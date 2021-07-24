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

## Compiling assets
echo "======================Compiling assets============================="
./make_style.sh
python3 manage.py collectstatic
python3 manage.py compilemessages
python3 manage.py compilejsi18n

## Setting up datebase tables
echo "======================Setting up datebase tables======================"
python3 manage.py migrate

python3 manage.py loaddata navbar
python3 manage.py loaddata language_small
python3 manage.py loaddata demo
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('kch', 'cndghks0213@gmail.com', '1234')" | python manage.py shell
# 이름, 이메일, 비밀번호를 설정하세요.

## Setting up Celery
echo "======================Setting up Celery============================"
sudo service redis-server start

## Running the server
echo "======================Running the server==========================="
# python3 manage.py runbridged
pip install redis

## Setting up uWSGI
echo "======================Setting up uWSGI============================"
pip3 install uwsgi
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/uwsgi.ini
SITE_PWD=$(pwd)
cd ..
cd dmojsite
DMOJ_PWD=$(pwd)
cd ..
cd site

sudo sed -i "s@<dmoj repo dir>@$SITE_PWD@g" uwsgi.ini
echo "Setting the <dmoj repo dir> for [uwsgi.ini]"
sudo sed -i "s@<virtualenv path>@$DMOJ_PWD@g" uwsgi.ini
echo "Setting the <virtualenv path> for [uwsgi.ini]"
# uwsgi --ini uwsgi.ini

## Setting up supervisord
echo "======================Setting up supervisord========================="
sudo apt-get install -y supervisor
cd /etc/supervisor/conf.d/
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/site.conf
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/bridged.conf
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/celery.conf

sudo sed -i "s@<path to virtualenv>@$DMOJ_PWD@g" *
echo "Setting the <path to virtualenv> for [*.conf]"
sudo sed -i "s@<path to site>@$SITE_PWD@g" *
echo "Setting the <path to site> for [*.conf]"
sudo sed -i "s@<user to run under>@root@g" *
echo "Setting the <user to run under> for [*.conf]"

sudo supervisorctl update
sudo supervisorctl status

## Setting up nginx
echo "======================Setting up nginx============================="
sudo apt-get install -y nginx
cd /etc/nginx/conf.d
sudo wget https://github.com/DMOJ/docs/raw/master/sample_files/nginx.conf

STATIC="/tmp/static"
sudo sed -i "s@<hostname>@site@g" nginx.conf
echo "Setting the <hostname> for [nginx.conf]"
sudo sed -i "s@<site code path>@$SITE_PWD@g" nginx.conf
echo "Setting the <site code path> for [nginx.conf]"
sudo sed -i "s@<django setting STATIC_ROOT, without the final /static>@$STATIC@g" nginx.conf
echo "Setting the <django setting STATIC_ROOT, without the final /static> for [nginx.conf]"

sudo nginx -t
sudo service nginx reload

## Configuration of event server
echo "======================Configuration of event server===================="
cd ~
cd site
cat > websocket/config.js << EOF
module.exports = {
    get_host: '127.0.0.1',
    get_port: 15100,
    post_host: '127.0.0.1',
    post_port: 15101,
    http_host: '127.0.0.1',
    http_port: 15102,
    long_poll_timeout: 29000,
};
EOF

npm install qu ws simplesets
pip3 install websocket-client