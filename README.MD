

DOMINIO: El navegador, antes de buscar la IP de '$(USER).42.fr' en las DNS de 
 la red, primero mirara si esta en el archivo '/etc/hosts' del host. Por tanto,
 asocio la IP del localhost (127.0.0.1) a ese dominio dentro de hosts. De este
 modo lo reconocera como valido y obtendra la IP 127.0.0.1
 El archivo /etc/hosts es un archivo de configuración del sistema que asocia 
 direcciones IP con nombres de dominio o "hostnames", funcionando como un mini DNS local.

SSL: NGINX necesita un certificado SSL para proteger el tunel de comunicacion de HTTP.
 Para el proyecto generare un certificado SSL autofirmado desde Makefile que se guarda en 
 el directorio del proyeco Inception y a traves del Dockerfile lo copio dentro del container.

VOLUMEN PERSISTENTE: creare el directorio ~/mydata en el host, que contendra 2 
 directorios mapeados a los volumenes de los containers mariadb y wordpress de los
  containers. Ahi guardare la informacion persistente.

SECRETS:
La informacion sensible estara discriminada en el proyecto para mantener la seguridad. 
Estara dividida en dos archivos: 
	'.env': archivo para almacenar variables de entorno y info mas general.
	'secrets':directorio para credenciales y contrasenyas.
Ambos estaran incluidos en el .gitignore para que no suban al repositorio. 
Se anyadiran al proyecto manualmente, una vez el evaluador lo haya descargado.

En un contexto profesional esto deberia manejarse inicializando Docker Swarm que 
crea mas seguridad y lo manjea de forma encryptada.

En cada container monto los secrets necesarios desde el host a dentro del contenedor 
y luego los exporto como variables de entorno de ese container. Cada container tiene
 su copia en memoria del .env externo y no ve los .env de los otros containers.



NGINX:
- Expone mi sitio WordPress al exterior a través del puerto HTTPS (443).
- Redirige las peticiones PHP al contenedor wordpress, que es el que ejecuta el código PHP.


