#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

PHP_TIMEZONE=$1
HHVM=$2

# Test if Apache is installed
sudo apachectl -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Test if Nginx is installed
sudo nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

if [[ $HHVM == "true" ]]; then
	echo ">>> Installing HHVM"

	# Get key and add to sources
	wget --quiet -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
	echo deb http://dl.hhvm.com/debian jessie main | sudo tee /etc/apt/sources.list.d/hhvm.list

	# Update
	sudo apt-get update > /dev/null 2>&1

	# Install HHVM
	# -qq implies -y --force-yes
	sudo apt-get install -qq hhvm || true

	# Start on system boot
	sudo update-rc.d hhvm defaults

	# Replace PHP with HHVM via symlinking
	sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60

	sudo service hhvm restart
else
	echo ">>> Installing PHP"

	sudo apt-get install -qq php php-common php-cli php-fpm php-mysql php-curl php-gd php-gmp php-mcrypt php-memcached php-imagick php-intl php-xdebug || true

	# Set run-as user for php-FPM processes to user/group "vagrant"
	# to avoid permission errors from apps writing to files
	sudo sed -i "s/user = www-data/user = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
	sudo sed -i "s/group = www-data/group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
	sudo sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
	sudo sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
	sudo sed -i "s/listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf

	# Up some limits
	sudo sed -i "s/max_execution_time = .*/max_execution_time = 180/" /etc/php/7.0/fpm/php.ini
	sudo sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/7.0/fpm/php.ini
	sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 20M/" /etc/php/7.0/fpm/php.ini
	sudo sed -i "s/post_max_size = .*/post_max_size = 20M/" /etc/php/7.0/fpm/php.ini

	sudo sed -i "s/max_execution_time = .*/max_execution_time = 180/" /etc/php/7.0/cli/php.ini
	sudo sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/7.0/cli/php.ini

	# xdebug Config
	cat > $(find /etc/php -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/php -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
xdebug.max_nesting_level = 350
EOF

	# PHP Error Reporting Config
	sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
	sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini

	# PHP Date Timezone
	sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/7.0/fpm/php.ini
	sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/7.0/cli/php.ini

	sudo service php-fpm restart || true

	# Using PHP-FPM for Nginx
	if [[ ${NGINX_IS_INSTALLED} -eq 0 ]]; then
		# Set PHP FPM to listen on TCP instead of Socket
		sudo sed -i "s/listen =.*/listen = 127.0.0.1:9000/" /etc/php/7.0/fpm/pool.d/www.conf
		# Set PHP FPM allowed clients IP address
		sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php/7.0/fpm/pool.d/www.conf
		sudo service nginx restart || true
	fi

	# If Apache is installed, get the php module for it
	if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
		# PHP Config for Apache
		sudo apt-get install -qq libapache2-mod-php || true
		# Should auto-enable
		# sudo a2enmod libapache2-mod-php
		sudo service apache2 restart || true
	fi
fi
