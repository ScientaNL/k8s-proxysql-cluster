#!/usr/bin/env bash
set -e

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
