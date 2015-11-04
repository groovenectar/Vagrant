#!/usr/bin/env bash

database_name="${1}"
database_user="${2}"
database_pass="${3}"
database_table_prefix="${4}"
remote_database_ssh_user="${5}"
remote_database_ssh_host="${6}"
remote_database_name="${7}"
remote_database_user="${8}"
remote_database_pass="${9}"
remote_database_table_prefix="${10}"
local_http_url="${11}"
local_https_url="${12}"
magento="${13}"

# Only if in interactive shell
# http://unix.stackexchange.com/a/26782/114856
if [[ $- == *i* ]] ; then
	echo
	echo ">>> Importing remote database"

	ignore_tables=""

	if [ ${magento} == "true" ]; then
		# Set the hostname in config
		# Run on first `vagrant ssh` then delete the script
		script="#!/usr/bin/env bash
		mysql --user=\"${database_user}\" --password=\"${database_pass}\" -e 'UPDATE \`${database_name}\`.\`${database_table_prefix}core_config_data\` SET value = \"${local_http_url}\" WHERE path = \"web/unsecure/base_url\"' \"${database_name}\"
		mysql --user=\"${database_user}\" --password=\"${database_pass}\" -e 'UPDATE \`${database_name}\`.\`${database_table_prefix}core_config_data\` SET value = \"${local_https_url}\" WHERE path = \"web/secure/base_url\"' \"${database_name}\"
		rm /etc/profile.d/9999_magento_mysql.sh"
		sudo echo "${script}" | sudo tee -a /etc/profile.d/9999_magento_mysql.sh
		sudo chmod u+x /etc/profile.d/9999_magento_mysql.sh
		sudo chown vagrant:vagrant /etc/profile.d/9999_magento_mysql.sh
		# Ignore unnecessary tables (e.g. logs) for data dump
		ignore_tables_array=( adminnotification_inbox dataflow_batch_export dataflow_batch_import log_customer log_quote log_summary log_summary_type log_url log_url_info log_visitor log_visitor_info log_visitor_online index_event report_event report_viewed_product_index report_compared_product_index catalog_compare_item )
		for table in "${ignore_tables_array[@]}"
		do
			ignore_tables+="--ignore-table=${remote_database_name}.${remote_database_table_prefix}${table} "
		done
		target_path="/home/vagrant/mysql_remote_pull.sh"
		sudo sed -i "s/--single-transaction/--single-transaction ${ignore_tables}/" target_path
		table_structures=${remote_database_name}
		for table in "${ignore_tables_array[@]}"
		do
			table_structures+=" ${remote_database_table_prefix}${table}"
		done
	fi

	echo
	echo "Enter SSH password, followed by remote database password (if prompted)"
	echo
	echo

	if [[ -n ${remote_database_pass} ]]; then
		ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump "${ignore_tables}"--single-transaction --user="${remote_database_user}" --password="\"${remote_database_pass}\"" "${remote_database_name}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
		if [ ${magento} == "true" ]; then
			echo
			echo "Enter SSH password once more to run additional Magento imports"
			echo
			echo

			ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --no-data --single-transaction --user="${remote_database_user}" --password="\"${remote_database_pass}\"" "${table_structures}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
		fi
	else
		ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump "${ignore_tables}"--single-transaction --user="${remote_database_user}" -p "${remote_database_name}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
		if [ ${magento} == "true" ]; then
			echo
			echo "Enter SSH followed by MySQL credentials once more to run additional Magento imports"
			echo
			echo

			ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --no-data --single-transaction --user="${remote_database_user}" -p "${table_structures}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
		fi
	fi
fi
