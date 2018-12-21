#!/bin/bash

# discover possible master node
mysql -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD} -h127.0.0.1 -P6032 -e "
    INSERT INTO proxysql_servers VALUES ('proxysql', 6032, 0, 'discovery');
    SAVE PROXYSQL SERVERS TO MEM;
    DELETE FROM proxysql_servers WHERE hostname = 'proxysql';
    LOAD PROXYSQL SERVERS TO RUNTIME;
";

# check if first
first_node_check=$(mysql -s -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD} -h127.0.0.1 -P6032 -e "
    SELECT COUNT(*) as count FROM proxysql_servers;
"| tail -n1);

if [[ ${first_node_check} -ne "0" ]]; then
    #add own ip to master node
    mysql -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD}  -hproxysql -P6032 -e "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUNTIME;
    ";
else
    #add own ip to proxysql_servers table
    mysql -u${ADMIN_USERNAME} -p${ADMIN_PASSWORD} -h127.0.0.1 -P6032 -e "
        INSERT INTO proxysql_servers VALUES ('${IP}', 6032, 0, '${IP}');
        LOAD PROXYSQL SERVERS TO RUNTIME;
    ";
fi
