#!/bin/sh
set -e

# first arg is `--k8s-cluster`
if [ "${1}" = "--k8s-cluster" ]; then
    /init-k8s-cluster.sh &
	set -- proxysql -f -c /proxysql-k8s-cluster.cnf
fi

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- proxysql "$@"
fi

exec "$@"