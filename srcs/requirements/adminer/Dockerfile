FROM debian:bullseye

# Instalacion de las dependencias minimas (Apache , php, extensiones necesarias
# Apache es uno de los servidores web más usados con PHP directamente porque
# incluye el módulo mod_php (puede interpretar PHP él mismo sin intermediarios).
# ca-certificates: contiene los certificados de las autoridades confiables.
# php: Interprete de php necesario para ejecutar Adminer
# php-mysqli: Extensión para que PHP pueda conectarse a MariaDB/MySQL
# apache2: Servidor web que se encargará de recibir las peticiones HTTP
# wget: Herramienta para descargar Adminer
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
	ca-certificates \
    php \
    php-mysqli \
    apache2 \
    wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Eliminar la página inicial que viene por defecto de Apache (en su
# lugar encontrara y cargara index.php del adminer) 
RUN rm -f /var/www/html/index.html

# Descargo Adminer y guardo como index.php en /var/www/html,
# que es la carpeta por defecto donde Apache sirve contenido.
# RUN wget "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php" -O /var/www/html/index.php
RUN wget "https://www.adminer.org/static/download/4.8.1/adminer-4.8.1.php" -O /var/www/html/index.php


# Como Apache corre con el user www-data cambiamos la propiedad de
# los archivos a ese usuario y le damos permisos de lectura y ejecucion.
RUN chown -R www-data:www-data /var/www/html && \
	chmod -R 755 /var/www/html

# El contenedor escucha por el puerto 80 (Apache).
# Accedere a Adminer a traves del proxy reverso de Nginx, de esta
# forma solo habra un container que sale al exterior y que maneja todo
# el trafico de entrada.
EXPOSE 80

# Apache, por defecto, corre como un demonio en segundo plano (daemon).
# Pero en Docker, el proceso principal debe estar en primer plano, si no,
# el contenedor se cierra. Con -D FOREGROUND le indicamos a Apache que se
# quede activo y visible como proceso principal del contenedor.
CMD ["apachectl", "-D", "FOREGROUND"]
