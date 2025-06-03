# debian OS penultimate stable version
FROM debian:bullseye

# INSTALACION DE PAQUETES
# Instala solo lo esencial y nginx
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

# nginx.conf:la conf global de nginx y default.conf:la conf especifica de mi wordpress
COPY ./conf/nginx.conf /etc/nginx/nginx.conf
COPY ./conf/default.conf /etc/nginx/conf.d/default.conf


# Establecemos al usuario y grupo propietarios como www-data (usuario por defecto de nginx en Debian)
# para que nginx pueda leer y servir el contenido del sitio web.
# Asignamos permisos 755 (rwxr-xr-x) al directorio del contenido
# Protegemos la clave privada SSL con permisos de solo lectura para root
# Redirigimos el log de acceso de nginx al stdout del contenedor (útil para logs en Docker)
# Redirigimos el log de errores de nginx al stderr del contenedor
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
