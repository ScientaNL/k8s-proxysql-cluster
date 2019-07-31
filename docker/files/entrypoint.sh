#!/usr/bin/env bash
set -e

touch /proxysql-liveness

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
elif [[ "${1}" = "--sync_default_hostgroup" ]]; then
	proxysql -f --initial &> /dev/null &
	set -- proxysql-cli sync:default-hostgroup
else
	set -- proxysql -f "$@"
fi

exec "${@}"
