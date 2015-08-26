#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

echo ">>> Installing MySQL Server"

[[ -z ${1} ]] && { echo "!!! MySQL root password not set. Check the Vagrant file."; exit 1; }

mysql_root_password="${1}"
mysql_enable_remote="${2}"

if [[ -n ${3} ]]; then
	database_name="${3}"
fi

if [[ -n ${4} ]]; then
	database_user="${4}"
fi

if [[ -n ${5} ]]; then
	database_pass="${5}"
fi

if [[ -n ${6} ]]; then
	remote_database_ssh_user="${6}"
fi

if [[ -n ${7} ]]; then
	remote_database_ssh_host="${7}"
fi

if [[ -n ${8} ]]; then
	remote_database_name="${8}"
fi

if [[ -n ${9} ]]; then
	remote_database_user="${9}"
fi

if [[ -n ${10} ]]; then
	remote_database_pass="${10}"
fi

if [[ -n ${11} ]]; then
	synced_folder="${11}"
fi

if [[ -n ${12} ]]; then
	mysql_remote_pull_script="${12}"
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

if [[ -n ${database_name} ]]; then
	echo ">>> Create new database"
	echo "CREATE DATABASE IF NOT EXISTS ${database_name};" | mysql -uroot -p"${mysql_root_password}"
	if [[ "${database_user}" != 'root' ]]; then
		# This creates the user if not exists
		echo "GRANT ALL PRIVILEGES ON ${database_name}.* TO '${database_user}'@'localhost' IDENTIFIED BY '${database_pass}';" | mysql -uroot -p"${mysql_root_password}"
		echo "FLUSH PRIVILEGES;" | mysql -uroot -p"${mysql_root_password}"
	fi
fi

if [[ -n ${remote_database_ssh_user} ]]; then
	# Can't prompt for SSH password during provision
	# ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --user="${remote_database_user}" --password="\"${remote_database_pass}\"" "${remote_database_name}" | mysql -uroot -p"${mysql_root_password}" "${database_name}"

	# So do it on first boot, in a subdir so we can delete it
	script_path="/home/vagrant/mysql_remote_pull.sh"
	link_path="/etc/profile.d/0001_mysql_remote_pull.sh"
	# Make this vagrant user so we can delete the file later without sudo
	sudo chown vagrant:vagrant /etc/profile.d

	if [[ ${mysql_remote_pull_script} =~ '://' ]]; then
		sudo curl --silent -L ${mysql_remote_pull_script} > ${script_path}
	else
		sudo cp ${synced_folder}/${mysql_remote_pull_script} ${script_path}
	fi

	sudo sed -i "s#=\"\${1}#=\"${database_name}#g" ${script_path}
	sudo sed -i "s#=\"\${2}#=\"${database_user}#g" ${script_path}
	sudo sed -i "s#=\"\${3}#=\"${database_pass}#g" ${script_path}
	sudo sed -i "s#=\"\${4}#=\"${remote_database_ssh_user}#g" ${script_path}
	sudo sed -i "s#=\"\${5}#=\"${remote_database_ssh_host}#g" ${script_path}
	sudo sed -i "s#=\"\${6}#=\"${remote_database_name}#g" ${script_path}
	sudo sed -i "s#=\"\${7}#=\"${remote_database_user}#g" ${script_path}
	sudo sed -i "s#=\"\${8}#=\"${remote_database_pass}#g" ${script_path}

	# Prompt to delete from startup
	printf "\n\necho && read -p \"Finished. Remove from startup? \" -n 1 -r && if [[ $REPLY =~ ^[Yy]$ ]]; then rm ${link_path}; echo; echo; fi" | sudo tee -a ${script_path}

	# Allow vagrant user to delete it
	sudo chmod u+x ${script_path}
	sudo chown vagrant:vagrant ${script_path}
	sudo ln -s ${script_path} ${link_path}
	sudo chown vagrant:vagrant ${link_path}
fi

# Make MySQL connectable from outside world without SSH tunnel
if [ ${mysql_enable_remote} == "true" ]; then
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