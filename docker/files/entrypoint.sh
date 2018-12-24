#!/usr/bin/env bash
set -e

cp -n /var/lib/proxysql-data/* /var/lib/proxysql/
if [[ "${1}" = "--cluster" ]]; then
    proxysql-cli init &> /dev/null &
	set -- proxysql -f --reload
elif [[ "${1}" = "--sync" ]]; then
	proxysql -f --initial &> /dev/null &
	set -- proxysql-cli sync
else
	set -- proxysql -f "$@"
fi

exec "${@}"