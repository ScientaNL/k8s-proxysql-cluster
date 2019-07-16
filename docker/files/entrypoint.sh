#!/usr/bin/env bash
set -e

if [[ ! -z $CONFIG_TEMPLATE && -s "$CONFIG_TEMPLATE" ]]; then
	envsubst < $CONFIG_TEMPLATE > /etc/proxysql.cnf
	echo "Replaced content and variables from $CONFIG_TEMPLATE into /etc/proxysql.cnf"
fi

if [[ "${1}" = "--cluster" ]]; then
    proxysql-cli init &
	set -- proxysql -f --initial
elif [[ "${1}" = "--sync_cluster" ]]; then
	proxysql -f --initial &> /dev/null &
	set -- proxysql-cli sync:cluster
else
	set -- proxysql -f "$@"
fi

# test
# count number of available mysql_servers
count=$(mysql -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h127.0.0.1 -P6032 -se "SELECT COUNT (*) FROM mysql_servers")
echo $count
# count number of offline mysql_servers
mysql -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h127.0.0.1 -P6032 -se "SELECT hostgroup_id,status FROM mysql_servers" | while read hostgroup_id status; do
	# use $hostgroup_id and $status variables
	echo "hostID: $hostgroup_id, status: $status"
	if [ ! "$status" = "ONLINE" ]; then
		var=$((var + 1))
		echo "It's offline..." $var
		echo "Found:" $var " of " $count " servers total"
			if [ $var = $count ]; then
			 # all server are offline
			 echo "Kill it with FIRE!"
			fi
	else
		echo "It's online... Proceed init"
	fi
done

exec "${@}"
