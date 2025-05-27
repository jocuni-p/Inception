# debian OS penultimate stable version
FROM debian:bullseye

# INSTALACION DE PAQUETES
# Instala solo lo esencial y nginx EL CERTIFICADO LO PUEDO CREAR FUERA Y IMPORTAR
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /etc/nginx/ssl /var/run/nginx /var/www/html

# Copy SSL certificates and config
COPY conf/ssl/nginx.crt /etc/nginx/ssl/
COPY conf/ssl/nginx.key /etc/nginx/ssl/

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY conf/default.conf /etc/nginx/conf.d/


# We change the owner and group of the folder /var/www/html to www-data (Default Nginx user in Debian)
# Also we set permissions for the same folder 
# Set proper permissions
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html && \
    chmod 400 /etc/nginx/ssl/nginx.key && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 443

# Default command when the container starts
# Launches Nginx web server in the foreground to prevent the container from exiting
CMD ["nginx", "-g", "daemon off;"]
