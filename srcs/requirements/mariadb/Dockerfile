FROM debian:bullseye

# Install MariaDB and all the necessary things to make it work.
# gettext: paquete que contiene la herramienta 'envsubst', que sustituye variables del .env en archivos.
# Instalo bash para poder lanzar el comando shell del HEALTCHECK del final
# We also delete temporary files to make it lighter
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y mariadb-server gettext bash && \
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

# Copio al container el script de arranque
COPY tools/entrypoint.sh /entrypoint.sh

# Le doy permisos de ejecucion al script
RUN chmod +x /entrypoint.sh

EXPOSE 3306

#HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=3 \
#  CMD-SHELL "mysqladmin ping -h localhost -u root --password=$(cat /run/secrets/db_root_password) || exit 1"
# Esto marca el contenedor como 'healthy' o 'unhealthy' segun este funcionando y responda correctamente o no.
# Usamos doble dólar ($$) para que Docker no lo interprete en tiempo de build
HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=3 \
  CMD bash -c 'mysqladmin ping -h localhost -u root --password="$$(cat /run/secrets/db_root_password)" || exit 1'

ENTRYPOINT ["/entrypoint.sh"]

