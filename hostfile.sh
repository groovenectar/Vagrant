#!/usr/bin/env bash

if [[ "$(uname)" == "Darwin" ]]; then
	# Untested
	hosts_file='/private/etc/hosts'
	vagrant_path='vagrant'
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
	hosts_file='/etc/hosts'
	vagrant_path=$(which vagrant)
elif [[ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]]; then
	# Untested
	hosts_file='winnt/system32/drivers/etc/hosts'
	vagrant_path='vagrant'
elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]]; then
	# Unsure
	echo "Not sure what to do with uname MINGW32_NT"
	exit
fi

if ! [[ -n ${vagrant_path} ]]; then
	echo "Vagrant does not appear to be installed"
	exit 1
fi

get_vagrant_status() {
	echo "Checking vagrant status..."
	# running (
	# poweroff (
	# not created (
	result=$(${vagrant_path} status)

	if [[ ${result} == *" running ("* ]]; then
		vagrant_status="running"
	elif [[ ${result} == *" poweroff ("* ]]; then
		vagrant_status="off"
	elif [[ ${result} == *" not created ("* ]]; then
		vagrant_status="purged"
	fi
}

get_ip_and_host () {
	echo "Getting info from vagrant..."
	{   # Scotch Box IP can be found under eth1
		guest_ip=$(vagrant ssh -c "echo -n \$(ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//')")
		guest_host=$(vagrant ssh -c "echo -n \$(hostname --fqdn)")
	} &> /dev/null

	# Strip spaces from variables
	guest_ip="${guest_ip// }"
	guest_host="${guest_host// }"

	if [[ -z "${guest_ip}" ]]; then
		echo "Could not determine VM IP"
		return 1
	fi

	if [[ -z "${guest_host}" ]]; then
		echo "Could not determine VM host"
		return 1
	fi

	# Tab separated
	host_entry=${guest_ip}$'\t'${guest_host}
}

ip () {
	if [[ -z "${guest_ip+xxx}" ]]; then
		get_ip_and_host
	fi

	echo ${guest_ip}
}

host () {
	if [[ -z "${guest_host+xxx}" ]]; then
		get_ip_and_host
	fi

	echo ${guest_host}
}

info () {
	if [[ -z "${guest_host+xxx}" ]] || [[ -z "${guest_ip+xxx}" ]]; then
		get_ip_and_host
	fi

	if [[ -n ${guest_host} ]]; then
		echo "Host: "${guest_host}
		echo " URL: http://"${guest_host}"/"
	else
		echo "Could not determine VM host"
	fi

	if [[ -n ${guest_ip} ]]; then
		echo "  IP: "${guest_ip}
	else
		echo "Could not determine VM IP"
	fi
}

hostfile() {
	if [[ -z "${1}" ]] || [[ -z "${2}" ]]; then
		echo "The hostfile method must have IP and host specified"
		exit 1
	fi

	# Gonna need superuser for this
	# https://unix.stackexchange.com/questions/28791/prompt-for-sudo-password-and-programmatically-elevate-privilege-in-bash-script
	if [[ $EUID != 0 ]]; then
		sudo "$0" ${ip} ${host}
		return $?
	fi

	ip=${1}
	host=${2}
	add_host_entry=${ip}$'\t'${host}

	if [[ ${host} == "localhost" ]]; then
		echo "Should not update host file entry for \"localhost\", aborting."
		echo "Reqested line to add was:"
		echo "${add_host_entry}"
		return 1
	fi

	# Escape periods and add whitespace regex
	# Searches the full IP Host entry
	# search=${ip//\./\\.}'\s+'${host//\./\\.}
	# Searches just the host
	search='\s+'${host//\./\\.}

	line=$(awk '/'${search}'/{ print NR; exit }' ${hosts_file})

	# Make sure the hostname is not already in the host file
	# If it isn't there yet, we can append it
	if ! [[ ${line} ]]; then
		# We should already be SU by this point
		echo $'\n'"${add_host_entry}" >> ${hosts_file}

		if [[ $? -eq 0 ]]; then
			echo "Host file entry added:"
		else
			echo "Could not write to host file:"
		fi
		echo "${add_host_entry}"
		return $?
	else
		# Get the full text of the found line
		line_text=$(sed -n "${line}p" ${hosts_file})
		search_with_ip=${ip//\./\\.}${search}

		# If there's already an entry with the IP *and* host
		# then we don't need to add or change anything
		if [[ ${line_text} =~ ${search_with_ip} ]]; then
			echo
			echo "Nothing to update, host file entry already exists:"
			echo ${add_host_entry}
			return 0
		fi

		# Otherwise we should prompt about updating it
		echo "An existing hostfile entry was found for ${host}:"
		echo ${line_text} # Unquoted to get max one space
		echo
		read -p "It will need to be updated. Is that okay? " -n 1 -r
		echo
		echo
		if [[ ! $REPLY =~ ^[Yy]$ ]]
		then
			echo "Keeping existing entry. The new (skipped) entry was:"
			echo "${add_host_entry}"
		    return 0
		fi

		sed -i "s/.*\s${host}.*/${add_host_entry}/" ${hosts_file}
		echo "Host file entry updated to:"
		echo "${add_host_entry}"
	fi
}

if [[ -n ${1} ]]; then
	if [[ -z "${2}" ]]; then
		echo "IP "${1}" provided, but missing next parameter hostname"
		exit 1
	fi

	ip=${1}
	host=${2}
else
	if [[ -z "${guest_ip+xxx}" ]] || [[ -z "${guest_host+xxx}" ]]; then
		get_vagrant_status
		if ! [[ ${vagrant_status} == "running" ]]; then
			echo "Vagrant is not currently running";
		    exit 1
		fi
		get_ip_and_host
		if ! [[ $? -eq 0 ]]; then
			echo "Could not get VM info"
			exit 1
		fi

		ip=${guest_ip}
		host=${guest_host}
	fi
fi

hostfile ${ip} ${host}
