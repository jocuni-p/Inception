#!/bin/bash

# Exportar los secretos ANTES de usarlos
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Waiting for MariaDB
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB is ready."

# Check for folder's permissions
chown -R www-data:www-data /var/www/html

# If WordPress is not installed we'll install it
if [ ! -f "/var/www/html/wordpress/wp-config.php" ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root

    echo "Creating configuration file for WordPress..."
    wp config create --allow-root \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb \
        --path=/var/www/html

    echo "Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    echo "Creating additional user..."
    wp user create --allow-root \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --role=author \
        --user_pass=${WP_USER_PASSWORD}

    echo "Additional configuration..."
    wp option update blogdescription "My first WordPress site using Docker" --allow-root
    wp rewrite structure '/%postname%/' --allow-root
    wp option update timezone_string "Europe/Madrid" --allow-root
    wp option update date_format "d/m/Y" --allow-root
    wp option update time_format "H:i" --allow-root
    wp option update permalink_structure "/%postname%/" --allow-root
    wp option update default_comment_status "closed" --allow-root
    wp option update default_ping_status "closed" --allow-root

    echo "WordPress installed and configured successfully!"
else
    echo "WordPress already installed."
fi

# Set up permissions again
chown -R www-data:www-data /var/www/html

# Start PHP-FPM in foreground mode
exec php-fpm7.4 -F

