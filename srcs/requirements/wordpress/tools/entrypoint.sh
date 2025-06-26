#!/bin/bash

# termina el script inmediatamente si cualquier comando falla
set -e

# Validación de secretos
for secret in \
  /run/secrets/db_user \
  /run/secrets/db_password \
  /run/secrets/wp_admin_user \
  /run/secrets/wp_admin_password \
  /run/secrets/wp_admin_email \
  /run/secrets/wp_user \
  /run/secrets/wp_user_password \
  /run/secrets/wp_user_email
do
  if [ ! -f "$secret" ]; then
    echo "[Entrypoint] Missing secret: $secret"
    exit 1
  fi
done

# Cargar y exportar secretos desde archivos montados
export MYSQL_USER=$(cat /run/secrets/db_user)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

export WP_ADMIN_USER=$(cat /run/secrets/wp_admin_user)
export WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
export WP_ADMIN_EMAIL=$(cat /run/secrets/wp_admin_email)

export WP_USER=$(cat /run/secrets/wp_user)
export WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
export WP_USER_EMAIL=$(cat /run/secrets/wp_user_email)

# Recargo las variables del .env por si este script no las viese 
# export DOMAIN_NAME=${DOMAIN_NAME}
# export MYSQL_DATABASE=${MYSQL_DATABASE}

# Validación de variables de entorno críticas
: "${DOMAIN_NAME:?Missing DOMAIN_NAME in .env}"
: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE in .env}"
: "${WP_TITLE:?Missing WP_TITLE in .env}"

# Directorio donde se instalará WordPress
WP_PATH="/var/www/html"

# Esperar a que mariadb esta lista
echo "[Entrypoint] Waiting for MariaDB to be ready..."
# until mysqladmin ping -h mariadb --silent; do
# until mysqladmin ping -h mariadb -u${MYSQL_USER} -p${MYSQL_PASSWORD} --silent; do
until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent; do
    sleep 2
done
echo "[Entrypoint] MariaDB is ready."

# Si no existe WordPress (descarga, crea file config, instala, configura, crea user, otras configuraciones)
if [ ! -f "$WP_PATH/wp-config.php" ]; then
    echo "[Entrypoint] Downloading WordPress..."
    wp core download --path="$WP_PATH" --allow-root

    echo "[Entrypoint] Creating configuration file for WordPress..."
    wp config create \
        --path="$WP_PATH" \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost=mariadb \
        --allow-root

    echo "[Entrypoint] Installing WordPress..."
    wp core install \
        --path="$WP_PATH" \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root

    echo "[Entrypoint] Creating additional user..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=author \
        --path="$WP_PATH" \
        --allow-root

    echo "[Entrypoint] Additional configuration..."
    wp option update blogdescription "Just another WordPress site" --path="$WP_PATH" --allow-root
    wp rewrite structure '/%postname%/' --path="$WP_PATH" --allow-root
    wp rewrite flush --path="$WP_PATH" --allow-root
    wp option update timezone_string "Europe/Madrid" --path="$WP_PATH" --allow-root
    wp option update date_format "d/m/Y" --path="$WP_PATH" --allow-root
    wp option update time_format "H:i" --path="$WP_PATH" --allow-root
    wp option update default_comment_status "open" --path="$WP_PATH" --allow-root
    wp option update comment_moderation "0" --path="$WP_PATH" --allow-root
    wp option update comment_previously_approved "0" --path="$WP_PATH" --allow-root
    wp option update default_ping_status "open" --path="$WP_PATH" --allow-root
    echo "[Entrypoint] WordPress installed and configured successfully!"
    # Asegurar permisos correctos
    chown -R www-data:www-data "$WP_PATH"
else
    echo "[Entrypoint] WordPress already installed. Skipping setup."
fi

# Iniciar PHP-FPM
exec php-fpm7.4 -F

