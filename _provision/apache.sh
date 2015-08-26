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

echo ">>> Installing Apache Server"

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
	hostname="$4"
fi

if [[ -z $5 ]]; then
	conf_path=""
else
	conf_path="$5"
fi

# Install Apache
# -qq implies -y --force-yes
sudo apt-get install -qq apache2

echo ">>> Configuring Apache"

# Add vagrant user to www-data group
sudo usermod -a -G www-data vagrant

# Disable default site
sudo a2dissite 000-default
# sudo rm -rf /var/www/html

# Add new sites
if [[ ! -f /etc/apache2/sites-avaialable/${hostname} ]]; then
	if [[ ${conf_path} =~ '://' ]]; then
		curl --silent -L ${conf_path} > vhost.conf
		sudo mv vhost.conf /etc/apache2/sites-available/${hostname}.conf
	else
		sudo cp ${synced_folder}/${conf_path} /etc/apache2/sites-available/${hostname}.conf
	fi
	sudo sed -i "s#localhost#${hostname}#g" /etc/apache2/sites-available/${hostname}.conf
	sudo sed -i "s#/var/www/html/\?#${public_folder}#g" /etc/apache2/sites-available/${hostname}.conf
	sudo a2ensite ${hostname}.conf
fi

# Apache modules
# Put on separate lines since some may cause an error if not installed
sudo a2enmod rewrite

# If PHP is installed or HHVM is installed, proxy PHP requests to it
if [[ $PHP_IS_INSTALLED -eq 0 || $HHVM_IS_INSTALLED -eq 0 ]]; then
	# PHP Config for Apache
	sudo apt-get install -qq libapache2-mod-php5
	# Should auto-enable
	# sudo a2enmod libapache2-mod-php5
fi

sudo service apache2 restart
