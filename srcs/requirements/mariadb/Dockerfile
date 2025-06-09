FROM debian:bullseye

# Install MariaDB and all the necessary things to make it work.
# gettext: paquete que contiene la herramienta 'envsubst', que sustituye variables del .env en archivos.
# We also delete temporary files to make it lighter
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y mariadb-server gettext && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /docker-entrypoint-initdb.d

# We create the folder where MariaDB will store its socket for local connections
# We change permissions to give mysql access to it
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Copia nuestra personalizacion de configuaracion de mariadb
#  para escuchar conexiones externas dentro de la red
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# Copy the local file to start de database to our container
# Script que crea base de datos y usuarios, usando variables del .env
COPY tools/init-db.sql /docker-entrypoint-initdb.d/init-db.template

# Create the entrypoint script that'll be executed when starting the container
# 'envsubst' sustituye variables de entorno por su valor en archivos de texto
# Luego lanzo mariadb con ese archivo ya bien rellenado
# It'll execute MariaDB in safe mode and we end up making the entrypoint.sh and executable file
RUN echo '#!/bin/bash\nset -e\n\
envsubst < /docker-entrypoint-initdb.d/init-db.template > /docker-entrypoint-initdb.d/init-db.sql\n\
exec mysqld_safe --init-file=/docker-entrypoint-initdb.d/init-db.sql' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 3306
ENTRYPOINT ["/entrypoint.sh"]

