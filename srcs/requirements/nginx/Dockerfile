# debian OS penultimate stable version
FROM debian:bullseye

#INSTALACION DE PAQUETES
#OJO php-fpm POTSER NO CAL INSTALAR-LO
# update and upgrade apt, install NGINX, Vim, Curl & OpenSSL(creacion/gestion de certificados)
RUN apt-get update && apt-get upgrade -y && apt-get install -y nginx vim curl openssl php-fpm

#GENERACION DEL CERTIFICADO
RUN	mkdir -p /etc/nginx/ssl && openssl req -x509 -nodes \
	-out /etc/nginx/ssl/nginx.crt \
	-keyout /etc/nginx/ssl/nginx.key \
	-subj "/C=ES/ST=Barcelona/L=Barcelona/O=42/OU=42/CN=jocuni-p.42.fr/UID=jocuni-p" && \
	mkdir -p /var/run/nginx
#Crea el directorio /etc/nginx/ssl para guardar los certificados.
#Genera un certificado autofirmado:
#	-x509: formato del certificado.
#	-nodes: no se pide contraseña para la clave privada.
#	-subj: define los datos del certificado.
#Crea también /var/run/nginx, usado por el daemon de NGINX para almacenar el PID.


# Copy the nginx.conf file from the host to the right location in the container
COPY conf/default.conf /etc/nginx/conf.d/default.conf

# We create a folder for the html files
RUN mkdir -p /var/www/html

# We change the owner and group of the folder /var/www/html to www-data (Default Nginx user in Debian)
# Also we set permissions for the same folder 
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

#Expone el puerto HTTPS para que el contenedor escuche trafico seguro.
EXPOSE 443

# Default command when the container starts
# Launches Nginx web server in the foreground to prevent the container from exiting
CMD ["nginx", "-g", "daemon off;"]

