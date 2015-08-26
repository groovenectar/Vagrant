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
	hostname="$4"
fi

if [[ -z $5 ]]; then
	conf_path=""
else
	conf_path="$5"
fi

if [[ -z $6 ]]; then
	vhost_conf_path=""
else
	vhost_conf_path="$6"
fi

# Install Nginx
# -qq implies -y --force-yes
sudo apt-get install -qq nginx || true

# Turn off sendfile to be more compatible with Windows, which can't use NFS
# sudo sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

# Set run-as user for PHP5-FPM processes to user/group "vagrant"
# to avoid permission errors from apps writing to files
# sudo sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
# sudo sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf
if [[ ${conf_path} =~ '://' ]]; then
	curl --silent -L ${conf_path} > nginx.conf
	sudo mv -f nginx.conf /etc/nginx/nginx.conf
else
	sudo cp -f ${synced_folder}/${conf_path} /etc/nginx/nginx.conf
fi
num_cores=$(grep processor /proc/cpuinfo | wc -l)
ulimit=$(ulimit -n)
worker_connections=$((${num_cores}*${ulimit}))
sudo sed -i "s/worker_processes.*/worker_processes ${num_cores};/" /etc/nginx/nginx.conf
sudo sed -i "s/worker_connections.*/worker_connections ${worker_connections};/" /etc/nginx/nginx.conf

# Up some values
sudo sed -i "s#\n\?fastcgi_connect_timeout.*##g" /etc/nginx/fastcgi_params
sudo printf "\nfastcgi_connect_timeout 65;" | sudo tee -a /etc/nginx/fastcgi_params
sudo sed -i "s#\n\?fastcgi_send_timeout 7200;.*##g" /etc/nginx/fastcgi_params
sudo printf "\nfastcgi_send_timeout 7200;" | sudo tee -a /etc/nginx/fastcgi_params
sudo sed -i "s#\n\?fastcgi_read_timeout.*##g" /etc/nginx/fastcgi_params
sudo printf "\nfastcgi_read_timeout 7200;" | sudo tee -a /etc/nginx/fastcgi_params

# Add vagrant user to www-data group
sudo usermod -a -G www-data vagrant

# Disable default site
sudo rm -f /etc/nginx/sites-enabled/default
# sudo rm -rf /var/www/html

# Add new site
if [[ ! -f /etc/nginx/sites-avaialable/${hostname} ]]; then
	if [[ ${vhost_conf_path} =~ '://' ]]; then
		curl --silent -L ${vhost_conf_path} > vhost.conf
		sudo mv -f vhost.conf /etc/nginx/sites-available/${hostname}
	else
		sudo cp -f ${synced_folder}/${vhost_conf_path} /etc/nginx/sites-available/${hostname}
	fi

	sudo sed -i "s#localhost#${hostname}#g" /etc/nginx/sites-available/${hostname}
	sudo sed -i "s#/var/www/html/\?#${public_folder}#g" /etc/nginx/sites-available/${hostname}
	sudo ln -sf /etc/nginx/sites-available/${hostname} /etc/nginx/sites-enabled/${hostname}
fi

if [[ $HHVM_IS_INSTALLED -ne 0 && $PHP_IS_INSTALLED -eq 0 ]]; then
	# PHP-FPM Config for Nginx
	sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
	sudo service php5-fpm restart || true
fi

sudo service nginx restart || true
