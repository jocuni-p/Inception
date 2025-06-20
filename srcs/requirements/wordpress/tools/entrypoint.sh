#!/bin/bash

# termina el script inmediatamente si cualquier comando falla
set -e

# Exporto los secretos al .env ANTES de usarlos
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)
export WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
export WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)
export WP_USER=$(cat /run/secrets/wp_user)
export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
export WP_USER_EMAIL=$(cat /run/secrets/wp_user_email)

# Waiting for MariaDB. Aseguro que mariadb esta lista y acepta solicitudes
# Va ejecutando 'SELECT 1' contra el host mariadb hasta que no falle (significa que esta listo)  
echo "Waiting for MariaDB to be ready..."
until mysql -h mariadb -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1" >/dev/null 2>&1; do
    sleep 2
done
echo "MariaDB is ready."

# Cambia el propietario del directorio donde se instala 
# WordPress a www-data (el usuario bajo el que corre PHP-FPM).
# Asegura que WordPress pueda leer/escribir correctamente.
chown -R www-data:www-data /var/www/html

# Install WordPress (if needed) and create and set users
# Usa wp-cli para descargar los archivos base de Wordpress
# --allow-root: evita errores si se ejecuta como root (necesario en contenedores).
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

# Seteo de nuevo los permisos del directorio para asegurar que los 
# nuevos archivos anyadidos tengan el propietario correcto
chown -R www-data:www-data /var/www/html

# Lanza PHP-FPM en primer plano (-F) para que el contenedor no se detenga
exec php-fpm7.4 -F

