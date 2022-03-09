#!/usr/bin/env bash
function proxysql_execute_query() {

    QUERY=${1}
    HOST=${2:-127.0.0.1}

    mysql -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h${HOST} -P6032 -s -N -e "${QUERY}"
}

function proxysql_execute_query_hr() {

    QUERY="${1}"
    HOST=${2:-127.0.0.1}

    mysql -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h${HOST} -P6032 -e "${QUERY}"
}

function mysql_execute_query() {

    QUERY=${1}
    HOST=${2:-127.0.0.1}

    mysql -u${MYSQL_ADMIN_USERNAME} -p${MYSQL_ADMIN_PASSWORD} -h${HOST} -s -N -e "${QUERY}"
}

function mysql_execute_query_hr() {

    QUERY=${1}
    HOST=${2:-127.0.0.1}

    mysql -u${MYSQL_ADMIN_USERNAME} -p${MYSQL_ADMIN_PASSWORD} -h${HOST} -e "${QUERY}"
}

function proxysql_wait_for_admin() {

    SLEEP=${1:-.1}

    while ! mysqladmin ping -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h127.0.0.1 -P6032 --silent; do
        sleep ${SLEEP}
    done
}

function proxysql_wait_for_admin_job() {

    SLEEP=${1:-.1}

    while ! mysqladmin ping -u${PROXYSQL_ADMIN_USERNAME} -p${PROXYSQL_ADMIN_PASSWORD} -h${PROXYSQL_SERVICE} -P6032 --silent; do
        sleep ${SLEEP}
    done
}

function proxysql_check_if_first() {
    proxysql_execute_query "SELECT COUNT(*) FROM proxysql_servers WHERE hostname NOT IN ('${PROXYSQL_SERVICE}', '${IP}')"
}

function proxysql_wait_for_servers() {

    VERSION=${1}
    SLEEP=${2:-.2}

    while [[ $(proxysql_execute_query "SELECT COUNT(*) FROM proxysql_servers WHERE hostname NOT IN ('${PROXYSQL_SERVICE}', '${IP}')") -lt 1 ]]; do
        sleep ${SLEEP}
    done

    sleep ${SLEEP}

}
