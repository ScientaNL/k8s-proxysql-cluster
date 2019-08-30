DELETE FROM mysql_servers;
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (1, 'mysql-0.mysql-gvr', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (2, 'mysql-0.mysql-gvr', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (2, 'mysql-1.mysql-gvr', 3306);
INSERT INTO mysql_servers (hostgroup_id, hostname, port) VALUES (2, 'mysql-2.mysql-gvr', 3306);

DELETE FROM mysql_group_replication_hostgroups;
insert into mysql_group_replication_hostgroups
(writer_hostgroup,backup_writer_hostgroup,reader_hostgroup, offline_hostgroup,active,max_writers,writer_is_also_reader,max_transactions_behind)
values (1,3,2,4,1,1,1,100);

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

DELETE FROM mysql_users;
insert into mysql_users(username, password, default_hostgroup) values('proxysql', 'proxysql', 1);

LOAD MYSQL USERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
