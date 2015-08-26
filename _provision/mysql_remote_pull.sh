#!/usr/bin/env bash

database_name="${1}"
database_user="${2}"
database_pass="${3}"
remote_database_ssh_user="${4}"
remote_database_ssh_host="${5}"
remote_database_name="${6}"
remote_database_user="${7}"
remote_database_pass="${8}"

echo
echo ">>> Importing remote database"
echo
echo "Enter SSH password, followed by remote database password (if prompted)"
echo
if [[ -n ${remote_database_pass} ]]; then
	ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --user="${remote_database_user}" --password="\"${remote_database_pass}\"" "${remote_database_name}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
else
	ssh "${remote_database_ssh_user}@${remote_database_ssh_host}" mysqldump --user="${remote_database_user}" -p "${remote_database_name}" | mysql -u"${database_user}" -p"${database_pass}" "${database_name}"
fi

