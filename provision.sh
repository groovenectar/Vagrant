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

echo ">>> Installing Ngrok"
sudo apt-get install -qq ngrok-client

cd ${public_folder}

# echo ">>> Checking out develop branch"
# git checkout develop

# MAGENTO - Set the hostname in config
# mysql --user="${dbuser[local]}" --password="${dbpass[local]}" -e 'UPDATE '"${database}"'.'"${dbprefix[local]}"'core_config_data SET value = "'"${http_url}"'" WHERE path = "web/unsecure/base_url"' "${database}"
# mysql --user="${dbuser[local]}" --password="${dbpass[local]}" -e 'UPDATE '"${database}"'.'"${dbprefix[local]}"'core_config_data SET value = "'"${https_url}"'" WHERE path = "web/secure/base_url"' "${database}"

# echo ">>> Installing Composer dependencies"
# composer install

# echo ">>> Running Laravel Migrations"
# php artisan migrate
# php artisan db:seed

# echo ">>> NodeJS"
# npm install && bower install && gulp