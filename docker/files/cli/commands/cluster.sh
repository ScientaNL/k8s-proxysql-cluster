#!/usr/bin/env bash
commands_add "init" "Add this node to the cluster"
command_init() {

    proxysql_wait_for_admin

    sleep 5

    isFirst=$(proxysql_check_if_first)

    if [[ "${isFirst}" -eq "0" ]]; then
        MASTERSERVER="127.0.0.1"
        command_sync:node
    else
        MASTERSERVER="${PROXYSQL_SERVICE}"
    fi

    proxysql_execute_query "
        DELETE FROM proxysql_servers
        WHERE hostname = '${PROXYSQL_SERVICE}';
    "

    sleep 3

    proxysql_execute_query "
        INSERT INTO proxysql_servers
        VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;
    " ${MASTERSERVER}

    sleep 5

    command_sync:checkOnline

    touch /proxysql-ready
}

commands_add "query" "[QUERY] perform mysql query on the cluster"
command_query() {
    proxysql_execute_query_hr "$1"
}

commands_add "query:users" "show mysql_users"
command_query:users() {
    proxysql_execute_query_hr "SELECT username, password, default_schema, default_hostgroup FROM mysql_users"
}

commands_add "query:servers" "show mysql_servers"
command_query:servers() {
    proxysql_execute_query_hr "SELECT * FROM mysql_servers"
}

commands_add "query:rules" "show mysql_servers"
command_query:rules() {
    proxysql_execute_query_hr "SELECT * FROM mysql_query_rules"
}

commands_add "query:nodes" "Show all the nodes of the cluster"
command_query:nodes() {
    proxysql_execute_query_hr "SELECT * FROM proxysql_servers;"
}

commands_add "remove" "Remove this node from the cluster"
command_remove() {
    proxysql_execute_query_hr "
        DELETE FROM proxysql_servers
        WHERE hostname = '${IP}';
        LOAD PROXYSQL SERVERS TO RUN;
    " ${PROXYSQL_SERVICE}
}

commands_add "sync:default-hostgroup" "Synchronize the default hostgroup from backends to the cluster"
command_sync:default-hostgroup() {
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

        if [[ ${?} -eq 0 ]]; then

            databaseCount=$(wc -l <<< "${availableDatabases}")

            if [[ ${newDefaultHostgroupCount} = -1 || $((databaseCount)) < $((newDefaultHostgroupCount)) ]]; then
                newDefaultHostgroupCount=$((databaseCount))
                newDefaultHostgroup=$((hostgroup))
            fi
        fi
    done <<< "${servers}"

    if [[ ${newDefaultHostgroupCount} -ne -1 ]]; then
        echo -e "\e[33m Setting default hostgroup for ${MYSQL_ADMIN_USERNAME}: ${newDefaultHostgroup} (${newDefaultHostgroupCount} databases) \e[0m"

        proxysql_execute_query_hr "
            REPLACE INTO mysql_users (username, password, default_hostgroup, transaction_persistent, fast_forward)
            VALUES ('${MYSQL_ADMIN_USERNAME}', '${MYSQL_ADMIN_PASSWORD}', '${newDefaultHostgroup}', 0, 0);
            LOAD MYSQL USERS TO RUN;
        " ${PROXYSQL_SERVICE}
    else
        echo -e "No suitable database found! Check your config"
    fi
}

commands_add "sync:node" "Synchronize this node from backends"
command_sync:node() {
    local resetDefaultHostgroup="${1:-1}" # set default value to 1

    proxysql_wait_for_admin

    proxysql_execute_query "
        DELETE FROM proxysql_servers
        WHERE hostname = '${PROXYSQL_SERVICE}';
        LOAD PROXYSQL SERVERS TO RUN;
    ";

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

        if [[ ${?} -eq 0 ]]; then

            databaseCount=$(wc -l <<< "${availableDatabases}")

            if [[ ${newDefaultHostgroupCount} = -1 || $((databaseCount)) < $((newDefaultHostgroupCount)) ]]; then
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
                    REPLACE INTO mysql_users (username, password, default_schema, default_hostgroup)
                    VALUES ('${username}', '${password}', '${database}', '${hostgroup}');"

                if [[ ${?} -eq 1 ]]; then
                    echo -e "Adding ${username}:${database} failed"
                fi
            done
        fi
    done <<< "${servers}"


    if [[ ${resetDefaultHostgroup} -eq 1 ]]; then
        if [[ ${newDefaultHostgroupCount} -ne -1 ]]; then
            echo -e "\e[33m Setting default hostgroup for ${MYSQL_ADMIN_USERNAME}: ${newDefaultHostgroup} (${newDefaultHostgroupCount} databases) \e[0m"
            proxysql_execute_query  "
                REPLACE INTO mysql_users (username, password, default_hostgroup, transaction_persistent, fast_forward)
                VALUES ('${MYSQL_ADMIN_USERNAME}', '${MYSQL_ADMIN_PASSWORD}', '${newDefaultHostgroup}', 0, 0);"
        else
            echo -e "No suitable database found! Check your config"
        fi
    else
        echo -e "Not replacing the default hostgroup for ${MYSQL_ADMIN_USERNAME}"
    fi

    proxysql_execute_query "
        LOAD MYSQL VARIABLES TO RUN;
        LOAD MYSQL QUERY RULES TO RUN;
        LOAD MYSQL USERS TO RUN;
        LOAD MYSQL SERVERS TO RUN;
        LOAD ADMIN VARIABLES TO RUN;";

    sleep 1
    echo -e " -- node synced -- "
}

commands_add "sync:cluster" "Synchronize this node from backends and update the cluster"
command_sync:cluster() {

    command_sync:node

    echo -e "\e[33m Joining cluster \e[0m"

    proxysql_execute_query "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUN;
    " "${PROXYSQL_SERVICE}";

    sleep 5

    echo -e "\e[33m Leaving cluster \e[0m"

    proxysql_execute_query "
        DELETE FROM proxysql_servers WHERE hostname = '${IP}';
        LOAD PROXYSQL SERVERS TO RUN;
    " "${PROXYSQL_SERVICE}";

    sleep 1
}

commands_add "sync:checkOnline" "Check if all available server are online"
command_sync:checkOnline() {

    echo -e "\e[33m Check RW and RO config entry \e[0m"

    confTotal=$(
    proxysql_execute_query "
        SELECT COUNT (*) FROM mysql_servers;
    ";
    )
    echo -e "\e[33m There are" $confTotal "server entry's to check \e[0m"

    sleep 5

    echo -e "\e[33m Check Offline quantity \e[0m"

    proxysql_execute_query "
        SELECT hostgroup_id,hostname,status FROM mysql_servers;
    " | while read hostgroup_id hostname status; do
	  # use $hostgroup_id and $status variables
	  echo "hostID: $hostgroup_id, hostname: $hostname, status: $status"
    # when working with a service "status" as indicator isn't always right
    if [ "`ping -c 1 $hostname`" ]; then
      echo "machine and online"
    else
      echo "service, so offline"
      foundTotal=$((foundTotal + 1))
      echo -e "\e[33m Found:" $foundTotal " of " $confTotal " servers total \e[0m"
      if [ $foundTotal = $confTotal ]; then
        # all servers are Offline
        echo -e "\e[33m All servers are offline, exit container... \e[0m"
        # lets exit this container
      else
        # next in line
        echo "next"
      fi
    fi
    done

    sleep 1

}
