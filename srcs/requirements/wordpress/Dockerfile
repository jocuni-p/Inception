FROM debian:bullseye

# Update and upgrade apt and install required packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y vim curl wget php7.4 php7.4-fpm php7.4-mysql mariadb-client && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install WP-CLI globally
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Configure PHP-FPM to listen on port 9000 instead of socket
RUN mkdir -p /run/php && \
    sed -i 's#listen = /run/php/php7.4-fpm.sock#listen = 9000#g' /etc/php/7.4/fpm/pool.d/www.conf

# Set working directory
WORKDIR /var/www/html/

# Copy entrypoint script into container
COPY /tools/entrypoint.sh /tmp/entrypoint.sh
RUN chmod +x /tmp/entrypoint.sh

# Crea el directorio y el archivo para los logs y le da permisos de usuario php-fpm 
RUN mkdir -p /var/log && \
    touch /var/log/php7.4-fpm.log && \
    chown -R www-data:www-data /var/log/php7.4-fpm.log

# Expose PHP-FPM port
EXPOSE 9000

# Run the entrypoint script (handles WordPress download/setup if not already present)
ENTRYPOINT ["/tmp/entrypoint.sh"]

