#!/usr/bin/env bash
function proxysql_execute_query() {

    QUERY=${1}
    HOST=${2:-127.0.0.1}

    mysql -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD} -h${HOST} -P6032 -s -N -e "${QUERY}"
}

function mysql_execute_query() {

    QUERY=${1}
    HOST=${2:-127.0.0.1}

    mysql -u${MONITOR_USERNAME} -p${MONITOR_PASSWORD} -h${HOST} -s -N -e "${QUERY}"
}

function proxysql_wait_for_admin() {

    SLEEP=${1:-.1}

    while ! mysqladmin ping -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD} -h127.0.0.1 -P6032 --silent; do
        sleep ${SLEEP}
    done
}

function proxysql_check_if_first() {
    proxysql_execute_query "SELECT COUNT(*) FROM proxysql_servers WHERE hostname NOT IN ('proxysql', '${IP}')"
}

function proxysql_wait_for_servers() {

    VERSION=${1}
    SLEEP=${2:-.2}

    while [[ $(proxysql_execute_query "SELECT COUNT(*) FROM proxysql_servers WHERE hostname NOT IN ('proxysql', '${IP}')") -lt 1 ]]; do
        sleep ${SLEEP}
    done

    sleep ${SLEEP}

}