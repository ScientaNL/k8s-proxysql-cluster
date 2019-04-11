#!/usr/bin/env bash
set -e

if [[ ! -z $CONFIG_TEMPLATE && -s "$CONFIG_TEMPLATE" ]]; then
	envsubst < $CONFIG_TEMPLATE > /etc/proxysql.cnf
	echo "Replaced content and variables from $CONFIG_TEMPLATE into /etc/proxysql.cnf"
fi

if [[ "${1}" = "--cluster" ]]; then
    proxysql-cli init &
	set -- proxysql -f --initial
elif [[ "${1}" = "--sync" ]]; then
	proxysql -f --initial &> /dev/null &
	set -- proxysql-cli sync
else
	set -- proxysql -f "$@"
fi

exec "${@}"
