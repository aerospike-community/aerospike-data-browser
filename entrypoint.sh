#!/bin/bash

service mysql start
sleep 1
mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED BY ''"
mysql -uroot -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''"
mysql -uroot -e "FLUSH PRIVILEGES"
mysql -uroot -e "CREATE DATABASE quix"
netstat -nl
sleep 1

echo -e "\n127.0.0.1 db\n" >> /etc/hosts
echo -e "127.0.0.1 backend\n" >> /etc/hosts
echo -e "127.0.0.1 frontend\n" >> /etc/hosts
echo -e "127.0.0.1 presto\n" >> /etc/hosts

export $(grep -v '^#' .env | xargs)

# start processes
/usr/lib/presto/bin/run-presto &
java -jar /quix-webapps/quix-web-spring/quix.jar &

pm2-runtime start ./ecosystem.config.js