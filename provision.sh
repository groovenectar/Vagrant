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
http_url=""
https_url=""

echo ">>> Installing Ngrok"
# sudo apt-get install -qq ngrok-client || true
wget -q https://dl.ngrok.com/ngrok_2.0.19_linux_amd64.zip
unzip ngrok_2.0.19_linux_amd64.zip
sudo mv ngrok /usr/bin/ngrok
rm ngrok_2.0.19_linux_amd64.zip

cd ${public_folder}

# echo ">>> Checking out develop branch"
# git checkout develop

# MAGENTO - Set the hostname in config
# Run on first `vagrant ssh` then delete the script
# script="#!/usr/bin/env bash
# mysql --user=\"${database_user}\" --password=\"${database_pass}\" -e 'UPDATE \`${database_name}\`.\`${database_table_prefix}core_config_data\` SET value = \"${http_url}\" WHERE path = \"web/unsecure/base_url\"' \"${database_name}\"
# mysql --user=\"${database_user}\" --password=\"${database_pass}\" -e 'UPDATE \`${database_name}\`.\`${database_table_prefix}core_config_data\` SET value = \"${https_url}\" WHERE path = \"web/secure/base_url\"' \"${database_name}\"
# rm /etc/profile.d/9999_magento_mysql.sh"
# sudo echo "${script}" | sudo tee -a /etc/profile.d/9999_magento_mysql.sh
# sudo chmod u+x /etc/profile.d/9999_magento_mysql.sh
# sudo chown vagrant:vagrant /etc/profile.d/9999_magento_mysql.sh
# echo "Magento config will be updated on first \`vagrant ssh\`"

# echo ">>> Installing Composer dependencies"
# composer install

# echo ">>> Running Laravel Migrations"
# php artisan migrate
# php artisan db:seed

# echo ">>> NodeJS"
# npm install && bower install && gulp
