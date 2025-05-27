FROM debian:11.1

# Install MariaDB and all the necessary things to make it work.
# We also delete temporary files to make it lighter
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y mariadb-server gettext && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /docker-entrypoint-initdb.d

# We create the folder where MariaDB will store its socket for local connections
# And we change the owner of mysql folders to mysql so the server can write on them
RUN mkdir -p /run/mysqld && \
    chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Copy the custom server configuration file
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/

# Copy the local file to start de database to our container
COPY tools/init-db.sql /docker-entrypoint-initdb.d/init-db.template

# Create the entrypoint script that'll be executed when starting the container
# Envsubst replaces the environment variables for its values
# It'll execute MariaDB in safe mode and we end up making the entrypoint.sh and executable file
RUN echo '#!/bin/bash\nset -e\n\
envsubst < /docker-entrypoint-initdb.d/init-db.template > /docker-entrypoint-initdb.d/init-db.sql\n\
exec mysqld_safe --init-file=/docker-entrypoint-initdb.d/init-db.sql' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 3306
ENTRYPOINT ["/entrypoint.sh"]

