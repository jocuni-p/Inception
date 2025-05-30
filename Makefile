# IMPORTANTE: Mi forma de proceder. Con el Makefile creo un certificado ssl que se guarda 
# en el host y a traves del Dockerfile lo copio al container.

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

$(SSL_DIR):
	@echo "[SSL] Creating SSL directory structure"
	@mkdir -p $@

$(SSL_KEY) $(SSL_CRT): | $(SSL_DIR)
	@if [ ! -f $(SSL_KEY) ] || [ ! -f $(SSL_CRT) ]; then \
		echo "[SSL] Generating new self-signed certificates for $(DOMAIN)"; \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout $(SSL_KEY) \
			-out $(SSL_CRT) \
			-subj "/CN=$(DOMAIN)"; \
		chmod 400 $(SSL_KEY); \
		echo "[SSL] Certificates generated successfully"; \
	else \
		echo "[SSL] Using existing certificates"; \
	fi

certs: $(SSL_KEY) $(SSL_CRT)

# ============= Main Rules ============ #

.PHONY: all setup build down status clean fclean re

all: build

setup: certs
	@echo "[SETUP] Initializing project environment"
	@mkdir -p $(DB_DIR) $(WP_DIR)
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "[SETUP] Adding $(DOMAIN) to /etc/hosts (sudo required)"; \
		echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
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
#	@docker ps -a --filter "name=inception_"
	@docker ps -a
	@echo "\n----------- Networks ------------"
	@docker network ls --filter "name=inception_"
	@echo "\n----------- Volumes ------------"
#	@docker volume ls --filter "name=inception_"
	@docker volume ls
	@echo "\n----------- Images -------------"
	@docker images --filter "reference=inception_*"
	@echo "\n---------- Disk Usage ----------"
	@docker system df

clean: down
	@echo "[CLEAN] Removing local volumes and directories"
	@-rm -rf $(DB_DIR) $(WP_DIR) 2>/dev/null || true
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true

fclean: clean
	@echo "[FCLEAN] Removing all project resources"
	@-docker rmi -f inception_nginx inception_wordpress inception_mariadb 2>/dev/null || true
	@-docker network rm inception_network 2>/dev/null || true
	@echo "[FCLEAN] Removing unused Docker objects"
	@docker system prune -af --filter "label=com.docker.compose.project=inception"

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


# # =============Variables============
# #
# PROJECT = inception
# DOMAIN = $(USER).42.fr

# MYDATA_DIR = ~/mydata # /home/$(USER)/mydata
# DB_DIR = $(MYDATA_DIR)/db_vol
# WP_DIR = $(MYDATA_DIR)/wp_vol
# # Contiene el nombre del comando que llama al docker compose en nuestro proyecto
# COMPOSE = docker compose -f srcs/docker-compose.yml -p $(PROJECT)


# # ============= SSL Certificates =============
# # Necesito generar un certificado SSL autofirmado para configurar HTTPS en mi NGINX

# SSL_DIR = srcs/requirements/nginx/conf/ssl
# SSL_KEY = $(SSL_DIR)/nginx.key
# SSL_CRT = $(SSL_DIR)/nginx.crt

# # Asegura que el directorio para los certificados exista antes de generarlos, sino lo crea
# $(SSL_DIR):
# 	@mkdir -p $@

# # Creara los 2 targets. El | verifica que exista una dependencia.
# # Crea un certificado autofirmado, sin contrasenya, valido por 1 anyo, 
# # con la clave rsa de 2048 bits, rutas de salida y establece mi dominio como el sujeto.
# $(SSL_KEY) $(SSL_CRT): | $(SSL_DIR)
# 	@echo "[SSL] Generating self-signed certificates"
# 	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
# 		-keyout $(SSL_KEY) \
# 		-out $(SSL_CRT) \
# 		-subj "/CN=$(DOMAIN)"


# # ================Rules===============
# #
# all: build

# # Genera el certificado
# # Asegura que los archivos de clave y certificado existan y estén listos.
# # En realidad no hace nada, solo asegura que las dependencias existan.
# certs: $(SSL_KEY) $(SSL_CRT)


# # Crea los volumenes locales y setea el dominio
# setup: certs
# 	@echo "[SETUP] Creating local volume directories in $(MYDATA_DIR)"
# 	@mkdir -p $(DB_DIR) $(WP_DIR)
# 	@echo "[SETUP] Ensuring $(DOMAIN) is in /etc/hosts"
# #	@grep -q "$(DOMAIN)" /etc/hosts || echo "⚠️  Warning: $(DOMAIN) not found in /etc/hosts"
# 	@grep -q "$(DOMAIN)" /etc/hosts || echo -e "\n ⚠️  Warning: Domain '$(DOMAIN)' not found in /etc/hosts\n\
#    For proper functionality, add this line to /etc/hosts:\n\
#    127.0.0.1 $(DOMAIN)\n\
#    You may need sudo privileges to edit this file.\n"
# #	Busca (-q modo silencioso) si el dominio "user.42.fr" esta presente en hosts.


# build: setup
# 	@echo "[BUILD] Building Docker images and starting containers"
# 	@$(COMPOSE) up -d --build
# 	@echo "================================================================="
# 	@echo "🔧 To ensure the domain '$(DOMAIN)' resolves locally,"
# 	@echo "   ensure it's in /etc/hosts like this: 127.0.0.1 $(DOMAIN)"
# 	@echo "================================================================="
# 	@echo "\n Use 'make status' to get containers' info"

# down:
# 	@echo "[DOWN] Stopping and removing containers and networks"
# 	$(COMPOSE) down
# # 	Detiene la aplicacion y elimina containers, networks, creados por docker-compose up.
# # 	Forma limpia de cerrar y salir. Sin ninguna option No elimina imagenes ni volumenes.

# status:
# 	@echo "\n*===========CONTAINERS===========*\n"
# 	docker ps -a
# 	@echo "\n*=============IMAGES=============*\n"
# 	docker images
# 	@echo "\n*============VOLUMES=============*\n"
# 	docker volume ls
# 	@echo "\n*============NETWORKS=============*\n"
# 	docker network ls
# 	@echo "\n*=====DISK SPACE COMPSUMTION=====*\n"
# 	docker system df

# clean: down
# 	@echo "[CLEAN] Removing local volume directories"
# 	@sudo rm -rf $(DB_DIR) $(WP_DIR)
# #	Necesito tener permisos de sudo para eliminar estos directorios, sino pedira password
# 	@echo "[CLEAN] Removing Docker volumes"
# 	@docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true


# fclean: clean
# 	@echo "[FCLEAN] Removing project images"
# 	@docker rmi nginx wordpress mariadb 2>/dev/null || true
# #	Con 2>/dev/null redirijo alli cualquier posible mensaje de error.
# #	Si no existen los volumenes, hay '|| true' para que no se pare el Makefile
# 	docker system prune -af --volumes

# re: fclean all

# .PHONY: all setup certs build status down clean fclean re

