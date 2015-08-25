#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# If HHVM is installed, assume PHP is *not*
[[ $HHVM_IS_INSTALLED -eq 0 ]] && { PHP_IS_INSTALLED=-1; }

echo ">>> Installing Nginx"

[[ -z $1 ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

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

if [[ -z $4 ]]; then
	hostname=""
else
	# There is a space, because this will be suffixed
	hostname="$4"
fi

# Install Nginx
# -qq implies -y --force-yes
sudo apt-get install -qq nginx

# Turn off sendfile to be more compatible with Windows, which can't use NFS
sudo sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

# Set run-as user for PHP5-FPM processes to user/group "vagrant"
# to avoid permission errors from apps writing to files
sudo sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sudo sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

# Add vagrant user to www-data group
sudo usermod -a -G www-data vagrant

# Delete default site
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-available/default
sudo rm -rf /var/www/html

# Add new site
if [[ ! -f /etc/nginx/sites-avaialable/${hostname} ]]; then
	sudo cp ${synced_folder}/_provision/nginx.conf /etc/nginx/sites-available/${hostname}
	sudo ln -sf /etc/nginx/sites-available/${hostname} /etc/nginx/sites-enabled/${hostname}
fi

sudo sed -i "s#localhost#${hostname}#g" /etc/nginx/sites-available/${hostname}
sudo sed -i "s#/var/www/html/\?#${public_folder//\//\\\/}#g" /etc/nginx/sites-available/${hostname}

if [[ $HHVM_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -eq 0 ]]; then
	# PHP-FPM Config for Nginx
	sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

	sudo service php5-fpm restart
fi

sudo service nginx restart