#!/bin/bash
set -e

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

export HOSTNAME=${HOSTNAME:-docker.for.mac.host.internal}
export PORT=${PORT:-3000}
export HOSTLIST=${HOSTLIST}
export TABLE_DESC_DIR=${TABLE_DESC_DIR:-etc/aerospike}
export SPLIT_NUMBER=${SPLIT_NUMBER:-4}
export CACHE_TTL_MS=${CACHE_TTL_MS:-1800000}
export DEFAULT_SET_NAME=${DEFAULT_SET_NAME:-__default}
export STRICT_SCHEMAS=${STRICT_SCHEMAS:-false}
export RECORD_KEY_NAME=${RECORD_KEY_NAME:-__key}
export RECORD_KEY_HIDDEN=${RECORD_KEY_HIDDEN:-true}
export ENABLE_STATISTICS=${ENABLE_STATISTICS:-false}
export INSERT_REQUIRE_KEY=${INSERT_REQUIRE_KEY:-true}
export CLIENT_LOG_LEVEL=${CLIENT_LOG_LEVEL:-WARN}

# Fill out conffile with above values
if [ -f /usr/lib/presto/etc/aerospike.properties.template ]; then
        envsubst < /usr/lib/presto/etc/aerospike.properties.template > /usr/lib/presto/etc/catalog/aerospike.properties
fi

export $(grep -v '^#' .env | xargs)

# start processes
/usr/lib/presto/bin/run-presto &
java -jar /quix-webapps/quix-web-spring/quix.jar &

pm2-runtime start ./ecosystem.config.js
