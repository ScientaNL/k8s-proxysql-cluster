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

    proxysql_execute_query "DELETE FROM proxysql_servers WHERE hostname = 'proxysql';
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;"

    proxysql_execute_query "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;" ${MASTERSERVER}

    touch /proxysql-ready
}

commands_add "cluster:query [QUERY]" "perform mysql query on the cluster"
command_query() {
    echo $(proxysql_execute_query "$1")
}

commands_add "show:nodes" "Show al the nodes of the cluster"
command_query:nodes() {
    proxysql_execute_query "SELECT * FROM proxysql_servers;"
}

commands_add "sync" "Synchronize from backends"
command_sync() {

    proxysql_wait_for_admin

    echo -e "\e[33mGetting users\e[0m"

    proxysql_execute_query "SELECT hostname, hostgroup_id FROM mysql_servers WHERE hostgroup_id NOT IN (
            SELECT reader_hostgroup FROM mysql_replication_hostgroups
        ) OR hostgroup_id IN (
            SELECT writer_hostgroup FROM mysql_replication_hostgroups
        ) " | while read hostname hostgroup; do

        availableDatabases=$(mysql_execute_query "
            SELECT QUOTE(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA
        " ${hostname});
        
        databasesString=$(echo "${availableDatabases}" | awk -vORS=, '{ print $1 }' | sed 's/,$/\n/')

        while read database; do
            proxysql_execute_query  "
                INSERT INTO mysql_query_rules (active,schemaname,destination_hostgroup,apply)
                VALUES (1,${database},'${hostgroup}',1);"
        done <<< "${availableDatabases}"

        mysql_execute_query "
            SELECT u.User, u.authentication_string, db.db
            FROM mysql.db as db
            JOIN mysql.user as u ON (u.User = db.User)
            WHERE db.db IN (${databasesString})
          " ${hostname} | while read username password database; do

                proxysql_execute_query "
                    INSERT INTO mysql_users (username, password, default_hostgroup, default_schema)
                    VALUES ('${username}', '${password}', '${hostgroup}', '${database}');"

            done

        done

    echo -e "\e[33mJoining cluster\e[0m"

    proxysql_execute_query "
        LOAD MYSQL VARIABLES TO RUN;
        LOAD MYSQL QUERY RULES TO RUN;
        LOAD MYSQL USERS TO RUN;
        LOAD MYSQL SERVERS TO RUN;
        LOAD ADMIN VARIABLES TO RUN;";

    sleep 1

    proxysql_execute_query "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;
    " "proxysql";

    sleep 10

    proxysql_execute_query "
        DELETE FROM proxysql_servers WHERE hostname = '${IP}';
        LOAD PROXYSQL SERVERS TO RUN;
    " "proxysql";

    sleep 5

    echo -e "-- DONE --"
}
