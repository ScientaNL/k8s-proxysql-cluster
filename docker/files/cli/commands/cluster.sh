#!/usr/bin/env bash

commands_add "init" "Add this node to the cluster"
command_init() {

    proxysql_wait_for_admin
    proxysql_check_if_first

    if [[ "${?}" -eq "1" ]]; then
        MASTERSERVER="127.0.0.1"
    else
        MASTERSERVER="proxysql"
    fi

    proxysql_execute_query "
        DELETE FROM proxysql_servers
        WHERE hostname = 'proxysql';

        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;
    "

    proxysql_execute_query "
        INSERT INTO proxysql_servers
        VALUES ('${IP}', 6032, 0, '${IP}');

        LOAD PROXYSQL SERVERS TO RUN;
    " ${MASTERSERVER}

    touch /proxysql-ready
}

commands_add "query [QUERY]" "perform mysql query on the cluster"
command_query() {
    proxysql_execute_query_hr "$1"
}

commands_add "query:users" "show mysql_users"
command_query:users() {
    proxysql_execute_query_hr "SELECT username, password,  FROM mysql_users"
}

commands_add "query:servers" "show mysql_servers"
command_query:servers() {
    proxysql_execute_query_hr "SELECT * FROM mysql_servers"
}

commands_add "query:rules" "show mysql_servers"
command_query:rules() {
    proxysql_execute_query_hr "SELECT * FROM mysql_query_rules"
}

commands_add "show:nodes" "Show al the nodes of the cluster"
command_query:nodes() {
    proxysql_execute_query_hr "SELECT * FROM proxysql_servers;"
}

commands_add "sync" "Synchronize from backends"
command_sync() {

    proxysql_wait_for_admin

    newDefaultHostgroup=-1
    newDefaultHostgroupCount=-1

    servers=$(proxysql_execute_query "
        SELECT hostname, hostgroup_id
        FROM mysql_servers
        WHERE hostgroup_id NOT IN (
            SELECT reader_hostgroup
            FROM mysql_replication_hostgroups
        ) OR hostgroup_id IN (
            SELECT writer_hostgroup
            FROM mysql_replication_hostgroups
        )
    ");

    while read hostname hostgroup; do

        echo -e "\e[33m Server: ${hostname} \n --- \e[0m"

        availableDatabases=$(mysql_execute_query "
            SELECT QUOTE(SCHEMA_NAME)
            FROM INFORMATION_SCHEMA.SCHEMATA
            WHERE SCHEMA_NAME NOT IN ('information_schema', 'performance_schema', 'sys')
        " ${hostname});

        databaseCount=$(wc -l <<< "${availableDatabases}")

        if [[ ${newDefaultHostgroupCount} = -1 || $((newDefaultHostgroupCount)) < $((databaseCount)) ]]; then
            newDefaultHostgroupCount=$((databaseCount))
            newDefaultHostgroup=$((hostgroup))
        fi

        databasesString=$(echo "${availableDatabases}" | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')

        echo -e "\e[33m Adding schema rules... \n --- \e[0m"

        proxysql_execute_query  "
            INSERT INTO mysql_query_rules (active, match_pattern, destination_hostgroup, apply )
            VALUES (1, '\/\*.*\s*hg\s*=\s*${hostgroup}\s*.*\*\/', '${hostgroup}', 1);"

        while read database; do

            proxysql_execute_query  "
                INSERT INTO mysql_query_rules (active, schemaname, destination_hostgroup, apply )
                VALUES (1, ${database}, '${hostgroup}', 1);"

        done <<< "${availableDatabases}"

        echo -e "\e[33m Adding users... \n --- \e[0m"

        mysql_execute_query "
            SELECT u.User, u.authentication_string, db.db
            FROM mysql.db as db
            JOIN mysql.user as u ON (u.User = db.User)
            WHERE db.db IN (${databasesString})
        " ${hostname} | while read username password database; do

            proxysql_execute_query "
                INSERT INTO mysql_users (username, password, default_schema)
                VALUES ('${username}', '${password}', '${database}');" &> /dev/null

            if [[ ${?} -eq 1 ]]; then
                echo -e "Adding ${username}:${database} failed"
            fi

        done

    done <<< "${servers}"

    echo -e "\e[33m Setting default route group: ${newDefaultHostgroup} (${newDefaultHostgroupCount} database) \e[0m"

    proxysql_execute_query  "
        UPDATE mysql_users SET default_hostgroup=${newDefaultHostgroup}, transaction_persistent=0
        WHERE username = '${MYSQL_ADMIN_USERNAME}';"

    proxysql_execute_query "
        LOAD MYSQL VARIABLES TO RUN;
        LOAD MYSQL QUERY RULES TO RUN;
        LOAD MYSQL USERS TO RUN;
        LOAD MYSQL SERVERS TO RUN;
        LOAD ADMIN VARIABLES TO RUN;";

    sleep 1

    echo -e "\e[33m Joining cluster \e[0m"

    proxysql_execute_query "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;
    " "proxysql";

    sleep 5

    echo -e "\e[33m Leaving cluster \e[0m"

    proxysql_execute_query "
        DELETE FROM proxysql_servers WHERE hostname = '${IP}';
        LOAD PROXYSQL SERVERS TO RUN;
    " "proxysql";

    echo -e " -- DONE -- "
    sleep 1
}
