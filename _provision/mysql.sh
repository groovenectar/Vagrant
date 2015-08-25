#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo ">>> Installing MySQL Server $2"

[[ -z "$1" ]] && { echo "!!! MySQL root password not set. Check the Vagrant file."; exit 1; }

# Debian 8 includes 5.5
# Need to revisit this if 5.6 is desired
if [ $2 == "5.6" ]; then
	# Add repo for MySQL 5.6
	wget http://repo.mysql.com/mysql-apt-config_0.3.6-1debian8_all.deb
	sudo debconf-set-selections <<< "mysql-apt-config mysql-apt-config/enable-repo select mysql-5.6"
	sudo dpkg -i mysql-apt-config_0.3.6-1debian8_all.deb

	# Update Again
	sudo apt-get update
fi

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $1"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $1"

# Install MySQL Server
# -qq implies -y --force-yes
sudo apt-get install -qq mysql-server mysql-client

# Make MySQL connectable from outside world without SSH tunnel
if [ $3 == "true" ]; then
	# enable remote access
	# setting the mysql bind-address to allow connections from everywhere
	sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

	# adding grant privileges to mysql root user from everywhere
	# thx to http://stackoverflow.com/questions/7528967/how-to-grant-mysql-privileges-in-a-bash-script for this
	MYSQL=`which mysql`

	Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;"
	Q2="FLUSH PRIVILEGES;"
	SQL="${Q1}${Q2}"

	$MYSQL -uroot -p$1 -e "$SQL"

	service mysql restart
fi