#!/bin/bash
set -e

# Cargar variables
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Espera ACTIVA a MariaDB (con credenciales reales)
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb -u$MYSQL_USER -p$MYSQL_PASSWORD --silent; do
    sleep 2
done

# Configuración inicial de WordPress
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "Setting up WordPress..."
    
    wp core download --path=/var/www/html --allow-root
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb" \
        --path=/var/www/html \
        --allow-root
    
    wp core install \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$(cat /run/secrets/wp_admin_user)" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="$(cat /run/secrets/wp_admin_email)" \
        --path=/var/www/html \
        --allow-root
    
    chown -R www-data:www-data /var/www/html
fi

# Configuración de PHP-FPM
echo "Starting PHP-FPM..."
exec php-fpm7.4 -F
