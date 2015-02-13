#!/bin/bash

dbname="surf_server"

# check socket, will need this later
[ ! -d "/tmp/mysql.sock" ] && sudo ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock

# create surf database
mysql -u root -e "create database $dbname"; 

# adds mapzone and maptier tables to database 
for mapzone in addons/sourcemod/gamedata/mapzones/*.sql
do
  mysql -u root $dbname < $mapzone
done

# adds sourcemod tables to database 
for script in addons/sourcemod/configs/sql-init-scripts/mysql/*.sql
do
  mysql -u root $dbname < $script
done

