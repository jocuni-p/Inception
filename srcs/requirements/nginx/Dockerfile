# debian OS penultimate stable version
FROM debian:bullseye

# INSTALACION DE PAQUETES
# Instala solo lo esencial y nginx
# El certificado lo creare (con Makefile) fuera del container y lo copiare
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    && rm -rf /var/lib/apt/lists/*
	# Limpia la cache de paquetes y temporales no necesarios despues
	# de la instalacion (aligera tamanyo de la imagen)

# Create necessary directories
# ssl:para certificados, nginx:para PID del proceso, html:dir raiz del wordpress
RUN mkdir -p /etc/nginx/ssl /var/run/nginx /var/www/html

# Copy SSL certificates and config
COPY conf/ssl/nginx.crt /etc/nginx/ssl/
COPY conf/ssl/nginx.key /etc/nginx/ssl/
# nginx.conf:la conf global de nginx y default.conf:la especifica de mi wordpress
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf


# We set the owner and proprietary group of the folder /var/www/html (in Debian Nginx runs under the user www-data)
# We set permissions for the folder 
# Protect private key permissions
# Redirect the logs to Docker
RUN chown -R www-data:www-data /var/www/html && \
	chmod -R 755 /var/www/html && \
    chmod 400 /etc/nginx/ssl/nginx.key && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Declaro que el contenedor escuchara en el puerto 443 (HTTPS), 
EXPOSE 443

# Default command when the container starts
# Launches Nginx web server in the foreground to prevent the container from exiting 
#(se desvincula del daemon para que no coja el proceso y cierre el container)
CMD ["nginx", "-g", "daemon off;"]
