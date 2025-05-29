# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jocuni-p <jocuni-p@student.42barcelona.com +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/05/29 14:23:57 by jocuni-p          #+#    #+#              #
#    Updated: 2025/05/29 17:48:09 by jocuni-p         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# NOTA: Desde Makefile creo un certificado ssl que se guarda en el directorio
# de Inception y a traves del Dockerfile lo copio dentro del container.

# ============= VARIABLES ============ #

PROJECT = inception
DOMAIN = $(USER).42.fr
MYDATA_DIR = ~/mydata
DB_DIR = $(MYDATA_DIR)/db_vol
WP_DIR = $(MYDATA_DIR)/wp_vol
COMPOSE = docker compose -f srcs/docker-compose.yml -p $(PROJECT)

# SSL Configuration
SSL_DIR = srcs/requirements/nginx/conf/ssl
SSL_KEY = $(SSL_DIR)/nginx.key
SSL_CRT = $(SSL_DIR)/nginx.crt

# ============= SSL SETUP ============ #

# NGINX necesita un certificado SSL para configurar el HTTPS.
# Para el proyecto generare un certificado SSL autofirmado y asi salgo del paso.

# # Asegura que el directorio para los certificados exista antes de generarlos, sino lo crea
$(SSL_DIR):
	@echo "[SSL] Creating SSL directory structure"
	@mkdir -p $@

# Creara los 2 targets. El | verifica que exista una dependencia.
# Crea un certificado autofirmado, sin contrasenya, valido por 1 anyo, 
# con la clave rsa de 2048 bits, rutas de salida y establece mi dominio como el sujeto.
$(SSL_KEY) $(SSL_CRT): | $(SSL_DIR)
	@if [ ! -f $(SSL_KEY) ] || [ ! -f $(SSL_CRT) ]; then \
		echo "[SSL] Generating certificates for $(DOMAIN) (user: $(USER))"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout $(SSL_KEY) \
			-out $(SSL_CRT) \
			-subj "/CN=$(DOMAIN)"; \
		chmod 400 $(SSL_KEY); \
		echo "[SSL] Certificates generated successfully"; \
	else \
		echo "[SSL] Using existing certificates"; \
	fi

# Genera el certificado
# # Asegura que los archivos clave y certificado existan y estén listos.
certs: $(SSL_KEY) $(SSL_CRT)


# ============= MAIN RULES ============ #

all: build

# Crea los volumenes locales y comprueba si mi dominio esta en /etc/hosts
setup: certs
	@echo "[SETUP] 🛠️  Initializing project environment for $(DOMAIN)"
	@echo "[SETUP] Creating local volume directories in $(MYDATA_DIR)"
	@mkdir -p $(DB_DIR) $(WP_DIR)
	@chmod 755 $(MYDATA_DIR)
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo ""; \
		echo "⚠️  Warning: Domain '$(DOMAIN)' not found in /etc/hosts  ⚠️"; \
		echo "For proper functionality, add this line to /etc/hosts:"; \
		echo "127.0.0.1 $(DOMAIN)"; \
		echo "You may need sudo privileges to edit this file."; \
	else \
		echo "[SETUP] $(DOMAIN) already in /etc/hosts"; \
	fi

build: setup
	@echo "[BUILD] Building containers with TLS 1.3"
	@$(COMPOSE) up -d --build
	@echo "\n✅ [SUCCESS] Inception project is running!"
	@echo "• Access: https://$(DOMAIN)"
	@echo "• Check containers: make status"
	@echo "• Stop services: make down"

down:
	@echo "[DOWN] Stopping containers and networks"
	@$(COMPOSE) down

status:
	@echo "\n📊 [STATUS] Checking services state"
	@echo "----------- Containers -----------"
#	OJO: PONER PREFIJO A LOS NOMBRES DE CONTAINERS Y IMAGES (inception_*)
#	@docker ps -a --filter "name=inception_"
	@docker ps -a
	@echo "\n----------- Networks ------------"
	@docker network ls --filter "name=inception_"
	@echo "\n----------- Volumes ------------"
	@docker volume ls --filter "name=inception_"
	@echo "\n----------- Images -------------"
#	@docker images --filter "reference=inception_*"
	@docker images
	@echo "\n---------- Disk Usage ----------"
	@docker system df

clean: down
	@echo "[CLEAN] Removing local volumes and directories"
	@-rm -rf $(DB_DIR) $(WP_DIR) 2>/dev/null || true
#	Necesito tener permisos de sudo para eliminar estos directorios, sino pedira password
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true

fclean: clean
	@echo "[FCLEAN] Removing all project resources"
	@-docker rmi -f inception_nginx inception_wordpress inception_mariadb 2>/dev/null || true
	@-docker network rm inception_network 2>/dev/null || true
	@echo "[FCLEAN] Removing SSL certificates"
	@-rm -rf $(SSL_DIR) 2>/dev/null || true
	@echo "[FCLEAN] Removing unused Docker objects"
	@docker system prune -af --filter "label=com.docker.compose.project=inception"
#	Elimina (-all -force) recursos no utilizados (objetos huérfanos) —como contenedores detenidos, 
#	redes no utilizadas, volúmenes huérfanos e imágenes dangling— solo si están 
#	asociados a la etiqueta 'inception'.
#	Con '2>/dev/null' redirijo alli cualquier posible mensaje de error.
#	Si no existen los volumenes, hay '|| true' para que no se pare el Makefile

re: fclean all

# ============= Help ============ #

help:
	@echo "\n🚀 Inception Project Makefile Help"
	@echo "make              Build and start all services (alias for make build)"
	@echo "make build        Build and start containers"
	@echo "make down         Stop containers"
	@echo "make status       Show containers status"
	@echo "make clean        Stop containers and remove volumes"
	@echo "make fclean       Full cleanup (containers, images, networks)"
	@echo "make re           Rebuild everything from scratch"
	@echo "make certs        Generate SSL certificates only"
	@echo "make help         Show this help message"


.PHONY: all setup build down status clean fclean re

