# Descargo la imagen de Debian11
FROM debian:bullseye

# Actualizo paquetes, instalo nginx sin accesorios, limpio y borro lista de lo instalado
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copio al container los archivos html de la web estatica
COPY ./html /usr/share/nginx/html


# Copio al container el file de conf de nginx
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

# Por defecto, los archivos copiados con COPY en Docker pertenecen al usuario root.
# Nginx en contenedores suele ejecutarse bajo el usuario nginx o www-data.
# Si los archivos son propiedad de root y Nginx no tiene permisos de lectura, la web no se mostrará (error 403 Forbidden).
# Cambio el propietario y grupo de los archivos al usuario www-data y aseguro permisos de lectura.
RUN chown -R www-data:www-data /usr/share/nginx/html && \
	chmod -R 755 /usr/share/nginx/html

EXPOSE 80

# Ejecuta nginx en primer plano y apaga el daemon para que no cierre el proceso.Creo??
CMD ["nginx", "-g", "daemon off;"]
