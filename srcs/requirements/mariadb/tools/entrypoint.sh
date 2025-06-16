#!/bin/bash

# termina el script inmediatamente si cualquier comando falla
set -e
# asigna los valores de 'secrets' montados en /run/secrets/ del container 
# a las variables de entorno que MYSQL usara durante la inicilaizacion 
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
# reemplaza las placeholders de la plantilla por los valores reales de las variables exportadas y lo guarda en init-db.sql 
envsubst < /docker-entrypoint-initdb.d/init-db.template > /docker-entrypoint-initdb.d/init-db.sql
# ejecuta el archivo init generado, iniciandose MySQL
exec mysqld_safe --init-file=/docker-entrypoint-initdb.d/init-db.sql