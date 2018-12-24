#!/usr/bin/env bash

readonly PROXYSQL_CLI_VERSION="1.0.0"

: "${ADMIN_USERNAME:=cluster1}"
: "${ADMIN_PASSWORD:=secret1pass}"

: "${MONITOR_USERNAME:=user}"
: "${MONITOR_PASSWORD:=pass}"

IP=$(hostname -i)
DIR=$(dirname "$(readlink -f "$0")")

#function
source ${DIR}/functions/commands.sh
source ${DIR}/functions/proxysql.sh

#commands
source ${DIR}/commands/cluster.sh

functionName="command_${1}";

if [[ $(type -t $functionName) = 'function' ]]; then
    shift
    $functionName "${@}"
elif [[ $1 = '--help' ]]; then
    commands_print
else
    echo "function ${1} not available";
fi

exit 0
