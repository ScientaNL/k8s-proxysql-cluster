while ! mysqladmin ping -ucluster1 -psecret1pass -h127.0.0.1 -P6032 --silent; do
  sleep 0.1
done

sleep .5

meip=$(hostname -i)

mysql -ucluster1 -psecret1pass -h127.0.0.1 -P6032 -e \
  "DELETE FROM proxysql_servers WHERE hostname = 'proxysql';";

test="$(mysql -s -ucluster1 -psecret1pass -h127.0.0.1 -P6032 -e \
  'SELECT COUNT(*) as count FROM proxysql_servers'  | tail -n1)"

if [ $test -ne "0" ]; then
  mysql -ucluster1 -psecret1pass -hproxysql -P6032 -e \
    "INSERT INTO proxysql_servers VALUES ('$meip', 6032, 0, '$meip');
    LOAD PROXYSQL SERVERS TO RUNTIME;";
else
  mysql -ucluster1 -psecret1pass -h127.0.0.1 -P6032 -e \
    "INSERT INTO proxysql_servers VALUES ('$meip', 6032, 0, '$meip');
    LOAD PROXYSQL SERVERS TO RUNTIME;";
fi
