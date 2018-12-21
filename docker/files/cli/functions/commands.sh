#!/usr/bin/env bash

declare -A commands=()

function commands_add() {
    commands[$1]=$2
}

function commands_print() {

    echo -e "\n\e[33m-- proxysql-cli -- \e[32m${PROXYSQL_CLI_VERSION}\e[0m\n"
    HELP=''
    for i in ${!commands[@]}; do
        HELP="${HELP}\n\e[34m${i}\e[0m^${commands[$i]}"
    done
    echo -e ${HELP} | column -t -x -s"^"
    echo -e ""
}