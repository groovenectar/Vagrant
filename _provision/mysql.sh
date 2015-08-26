#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo ">>> Installing MySQL Server"

[[ -z "$1" ]] && { echo "!!! MySQL root password not set. Check the Vagrant file."; exit 1; }

if [[ ! -z $3 ]]; then
	database_name="$3"
fi

if [[ ! -z $4 ]]; then
	database_user="$4"
fi

if [[ ! -z $5 ]]; then
	database_pass="$5"
fi

if [[ ! -z $6 ]]; then
	remote_database_ssh_user="$6"
fi

if [[ ! -z $7 ]]; then
	remote_database_ssh_host="$7"
fi

if [[ ! -z $8 ]]; then
	remote_database_user="$8"
fi

if [[ ! -z $9 ]]; then
	remote_database_pass="$9"
fi

if [[ ! -z $10 ]]; then
	remote_database_pass="$10"
fi

# if [ ${mysql_version} == "5.6" ]; then
# 	# Add repo for MySQL 5.6
# 	# Need to revisit this if 5.6 is desired, this route does not seem to work
# 	wget http://repo.mysql.com/mysql-apt-config_0.3.6-1debian8_all.deb
# 	sudo debconf-set-selections <<< "mysql-apt-config mysql-apt-config/enable-repo select mysql-5.6"
# 	sudo dpkg -i mysql-apt-config_0.3.6-1debian8_all.deb
#
# 	# Update Again
# 	sudo apt-get update
# fi

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $1"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $1"

# Install MySQL Server
# -qq implies -y --force-yes
sudo apt-get install -qq mysql-server mysql-client

if [[ ! -z ${database_name} ]]; then
	echo ">>> Create new database"
	echo "CREATE DATABASE IF NOT EXISTS ${database_name};" | mysql -uroot -p"${mysql_root_password}"
	# This creates the user if not exists
	echo "GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}'@'localhost' IDENTIFIED BY '${database_pass}';" | mysql -uroot -p"${mysql_root_password}"
	echo "FLUSH PRIVILEGES;" | mysql -uroot -p"${mysql_root_password}"
fi

if [[ ! -z ${remote_database_ssh_user} ]]; then
	ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --user="${remote_database_user}" --password="\"${remote_database_pass}\"" "${remote_database_name}" | mysql -uroot -p"${mysql_root_password}" "${database_name}"
fi

# Make MySQL connectable from outside world without SSH tunnel
if [ $2 == "true" ]; then
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