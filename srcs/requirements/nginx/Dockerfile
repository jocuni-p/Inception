# debian OS penultimate stable version
FROM debian:bullseye

# INSTALACION DE PAQUETES
# Instala solo lo esencial y nginx
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
	ca-certificates \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	# Limpia la cache de paquetes y temporales no necesarios despues
	# de la instalacion (aligera tamanyo de la imagen)

# Create necessary directories (ssl para certs y html para wordpress)
RUN mkdir -p /etc/nginx/ssl /var/www/html 

# Copy SSL certificates
COPY conf/ssl/nginx.crt /etc/nginx/ssl/
COPY conf/ssl/nginx.key /etc/nginx/ssl/

# Copia los files de configuarcion al container
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf

# Establecemos al usuario y grupo propietarios como www-data (usuario por defecto de nginx en Debian)
# para que nginx pueda leer y servir el contenido del sitio web.
# Asignamos permisos 755 (rwxr-xr-x) al directorio del contenido
# Protegemos la clave privada SSL con permisos de solo lectura para root
# Creamos enlaces simbólicos (con ln -s) de los archivos de log de Nginx 
# hacia la salida estándar del contenedor Docker para sean visibles desde
# fuera del contenedor usando 'docker logs'
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod 400 /etc/nginx/ssl/nginx.key && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Declaro que el contenedor escuchara en el puerto 443 (HTTPS), 
EXPOSE 443

# Default command when the container starts
# Launches Nginx web server in the foreground to prevent the container from exiting 
#(Lo desvincula del daemon para que que no se cierre)
CMD ["nginx", "-g", "daemon off;"]
