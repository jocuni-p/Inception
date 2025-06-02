# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jocuni-p <jocuni-p@student.42barcelona.com +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/05/29 14:23:57 by jocuni-p          #+#    #+#              #
#    Updated: 2025/05/30 15:39:53 by jocuni-p         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# NOTA: Desde Makefile creo un certificado ssl que se guarda en el directorio
# del proyeco Inception y a traves del Dockerfile lo copio dentro del container.
# Se crearan 2 volumenes que estaran mapeados al directorio '~/mydata' del host
# donde se guardara la informacion de forma persistente (independientemente del
# estado de los containers). 
# ============= VARIABLES ============ #

PROJECT = inception
DOMAIN = $(USER).42.fr
MYDATA_DIR = /home/$(USER)/mydata
DB_DIR = $(MYDATA_DIR)/db_vol
WP_DIR = $(MYDATA_DIR)/wp_vol
COMPOSE = docker compose -f srcs/docker-compose.yml -p $(PROJECT)

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

# Creara los 2 targets. 
# El '|' verifica solo que exista la dependencia. No reconstruye cada vez que cambie.
# Crea un certificado autofirmado, sin contrasenya, valido por 1 anyo, 
# con la clave rsa de 2048 bits, rutas de salida y establece mi dominio como sujeto.
$(SSL_KEY) $(SSL_CRT): | $(SSL_DIR)
	@if ! command -v openssl > /dev/null 2>&1; then \
        echo "Error: openssl is not installed."; \
        exit 1; \
	fi
	@if [ ! -f $(SSL_KEY) ] || [ ! -f $(SSL_CRT) ]; then \
		echo "[SSL] Generating certificates for $(DOMAIN) (user: $(USER))"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout $(SSL_KEY) \
			-out $(SSL_CRT) \
			-subj "/CN=$(DOMAIN)"; \
		chmod 400 $(SSL_KEY) $(SSL_CRT); \
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
#	Para que construya sin guardar las capas en la cache:
#	@$(COMPOSE) build --no-cache
#	@$(COMPOSE) up -d
	@echo "\n✅ [SUCCESS] Inception project is running!"
	@echo "============================================"
	@echo "• Access: https://$(DOMAIN)"
	@echo "• Check containers: make status"
	@echo "• Stop services: make down"
	@echo "• Help: make help"
	@echo "============================================"

status:
	@echo "\n📊 [STATUS] Checking services state"
	@echo "----------- Containers -----------"
#	@docker ps -a --filter "name=inception_"
	@docker ps -a
	@echo "\n----------- Networks ------------"
	@docker network ls --filter "name=inception_"
#	@docker network ls
	@echo "\n----------- Volumes ------------"
#	@docker volume ls --filter "name=inception_"
	@docker volume ls
	@echo "\n----------- Images -------------"
#	@docker images --filter "reference=inception_*"
	@docker images
	@echo "\n---------- Disk Usage ----------"
	@docker system df

down:
	@echo "[DOWN] Stopping and removing containers and network (doesn't remove persistent data)"
	@$(COMPOSE) down

clean: 
	@echo "[CLEAN] Removing containers, network and volumes (local + containerized and its directories)"
	@$(COMPOSE) down
	@-rm -rf $(DB_DIR) $(WP_DIR) 2>/dev/null || true
#	Necesito tener permisos de sudo para eliminar estos directorios de arriba, sino pedira password
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true
#	@$(COMPOSE) down
#	'-' al inicio, ignora errores en los comandos criticos

fclean: clean
	@echo "[FCLEAN] Removing ALL project resources"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "[FCLEAN] Removing SSL certificates"
	@-rm -rf $(SSL_DIR) 2>/dev/null || true
#	--rmi all: elimina todas las imágenes asociadas al proyecto, incluido cache
#	--volumes: borra los volúmenes anónimos creados por docker-compose (no afecta a db_vol y wp_vol).
#	--remove-orphans: elimina contenedores sueltos que comparten la misma red del proyecto.


re: fclean all

# ============= Help ============ #

help:
	@echo "\n🚀 Inception Project Makefile Help"
	@echo "make all          Build and start all services (alias for make build)"
	@echo "make build        Build and start containers"
	@echo "make down         Stop containers (remove: containers and network)"
	@echo "make status       Show all containers' info"
	@echo "make clean        Remove containers, network, intern volumes"
	@echo "make fclean       Full cleanup (containers, network, images, intern volumes, ssl certificate from container and other related files)"
	@echo "make re           Rebuild everything from scratch"
	@echo "make certs        Generate SSL certificates only"


.PHONY: all setup build down status clean fclean re help

