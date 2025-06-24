#!/bin/bash

# Uso el 'envsubst' porque estoy usando un template SQL con variables ${...} y el archivo .sql no entiende las variables de shell.

# termina el script inmediatamente si cualquier comando falla
set -e

echo "[Entrypoint] Reading secrets..."
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
# export MYSQL_DATABASE=${MYSQL_DATABASE}

echo "[Entrypoint] Preparing init script with envsubst..."
envsubst < /docker-entrypoint-initdb.d/init-db.template > /docker-entrypoint-initdb.d/init-db.sql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "[Entrypoint] First time setup - initializing DB"
    chown -R mysql:mysql /var/lib/mysql
    mysqld --user=mysql --bootstrap < /docker-entrypoint-initdb.d/init-db.sql
else
    echo "[Entrypoint] Existing database found, skipping init"
fi

echo "[Entrypoint] Starting MariaDB normally"
exec mysqld_safe

