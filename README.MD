

SECRETS:
La informacion sensible estara discriminada en el proyecto para mantener la seguridad. 
Estara dividida en dos archivos: 
	'.env': archivo para almacenar variables de entorno y info mas general.
	'secrets':directorio para credenciales y contrasenyas.
Ambos estaran incluidos en el .gitignore para que no suban al repositorio. 
Se anyadiran al proyecto manualmente, una vez el evaluador lo haya descargado.

En un contexto profesional esto deberia manjarse inicializando Docker Swarm que 
crea mas seguridad y lo manjea de forma encryptada.

NGINX:
✅ Expone tu sitio WordPress al exterior a través del puerto HTTPS (443).

✅ Redirige las peticiones PHP al contenedor wordpress, que es el que ejecuta el código PHP.

