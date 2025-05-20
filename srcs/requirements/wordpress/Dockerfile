FROM debian:bullseye

# Update and upgrade apt and install mariadb-server
RUN apt-get update && apt-get upgrade -y && \
	apt-get install -y vim curl wget php7.4 php7.4-fpm php7.4-mysql mariadb-client

# Download the desired version of Wordpress in the desired folder, decompress it and remove the .tar file
# create the folder to store tmp files(if not created)

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp \
&& chmod +x /usr/local/bin/wp

RUN mkdir -p /run/php \
&& sed -i 's#listen = /run/php/php7.4-fpm.sock#listen = 9000#g' /etc/php/7.4/fpm/pool.d/www.conf


RUN wget https://wordpress.org/wordpress-6.7.2.tar.gz -P /var/www/html && \
	cd /var/www/html && tar -xzf wordpress-6.7.2.tar.gz && rm wordpress-6.7.2.tar.gz
# Give root rights to write in the wordpress folder and create the folder to store tmp files(if not created)

RUN chown -R www-data:www-data /var/www/html/ \
    && chmod -R 755 /var/www/html/

# Set working directory

WORKDIR /var/www/html/

# Copy our config file and script to execute it in case is not configured already
COPY /tools/entrypoint.sh /tmp/entrypoint.sh

# Again we substitute the .conf file from php so it listens to port 9000
# & "clear_env = no" to keep env variables while php-fpm is being used
# COPY /conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
RUN chmod +x /tmp/entrypoint.sh

# Expose port for PHP-FPM
EXPOSE 9000

# Start PHP-FPM and WordPress setup
ENTRYPOINT ["/tmp/entrypoint.sh"]

