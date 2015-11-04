#!/usr/bin/env bash

echo ">>> Additional provisioning"

# Get variables from Vagrantfile
if [[ -z $1 ]]; then
	server_ip="127.0.0.1"
else
	server_ip="$1"
fi

if [[ -z $2 ]]; then
	public_folder="/vagrant"
else
	public_folder="$2"
fi

if [[ -z $3 ]]; then
	synced_folder="/vagrant"
else
	synced_folder="$3"
fi

if [[ ! -z $4 ]]; then
	hostname="$4"
fi

if [[ ! -z $5 ]]; then
	mysql_root_password="$5"
fi

if [[ ! -z $6 ]]; then
	database_name="$6"
fi

if [[ ! -z $7 ]]; then
	database_user="$7"
fi

if [[ ! -z $8 ]]; then
	database_pass="$8"
fi

database_table_prefix=""
http_url="http://${hostname}/"
https_url="http://${hostname}/"

echo ">>> Installing Ngrok"
# sudo apt-get install -qq ngrok-client || true
wget -q https://dl.ngrok.com/ngrok_2.0.19_linux_amd64.zip
unzip ngrok_2.0.19_linux_amd64.zip
sudo mv ngrok /usr/bin/ngrok
rm ngrok_2.0.19_linux_amd64.zip

# echo ">>> Installing Modman"
# sudo bash < <(wget -q --no-check-certificate -O - https://raw.github.com/groovenectar/modman/master/modman-installer)

cd ${public_folder}

# echo ">>> Checking out develop branch"
# git checkout develop

# echo ">>> Installing Composer dependencies"
# composer install

# echo ">>> Running Laravel Migrations"
# php artisan migrate
# php artisan db:seed

# echo ">>> NodeJS"
# npm install && bower install && gulp
