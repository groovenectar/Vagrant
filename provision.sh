#!/usr/bin/env bash

echo ">>> Extra provisioning"

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

if [[ -z $4 ]]; then
	hostname=""
else
	# There is a space, because this will be suffixed
	hostname=" $4"
fi

# MySQL database
# echo "CREATE DATABASE IF NOT EXISTS blog;" | mysql -uroot