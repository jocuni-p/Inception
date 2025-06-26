# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: jocuni-p <jocuni-p@student.42barcelona.com +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2025/05/29 14:23:57 by jocuni-p          #+#    #+#              #
#    Updated: 2025/06/07 17:29:51 by jocuni-p         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #


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

# NGINX necesita un certificado SSL para proteger el tunel de comunicacion de HTTP.
# Para poder hacer el proyecto generare un certificado SSL autofirmado (test para desarrollo)

# Asegura que el directorio para los certificados exista antes de generarlos, sino lo crea
$(SSL_DIR):
	@echo "[SSL] Creating SSL directory structure"
	@mkdir -p $@

# Creara los 2 targets. 
# El '|' verifica solo que exista la dependencia. No reconstruye si esta cambia.
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


# ============= MAIN RULES ============ #


all: certs setup build

# Genera el certificado
# # Asegura que los archivos clave y certificado existan y estén listos.
certs: $(SSL_KEY) $(SSL_CRT)

# Crea e inicializa los volumenes locales persistentes y comprueba si el dominio esta en /etc/hosts
setup: 
	@echo "[SETUP] Creating local volume directories in $(MYDATA_DIR)"
	@mkdir -p $(DB_DIR) $(WP_DIR)
	@chmod 755 $(MYDATA_DIR)
	@echo "[SETUP] 🛠️  Initializing project environment for $(DOMAIN)"
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo ""; \
		echo "⚠️  Warning: Domain '$(DOMAIN)' not found in /etc/hosts ⚠️"; \
		echo "For proper functionality, add this line to /etc/hosts:"; \
		echo "127.0.0.1 $(DOMAIN)"; \
		echo "You may need sudo privileges to edit this file."; \
	else \
		echo "[SETUP] $(DOMAIN) already in /etc/hosts"; \
	fi

# Construye y levanta los containers en segundo plano (detached)
build:
	@echo "[BUILD] Building containers with TLS 1.3"
	@$(COMPOSE) up -d --build
#	Para que construya sin guardar las capas en la cache:
#	@$(COMPOSE) build --no-cache
#	@$(COMPOSE) up -d
	@echo "\n✅ [SUCCESS] Inception project is running!"
	@echo "============================================"
	@echo "• Access: https://$(DOMAIN)"
	@echo "• Check containers: make status"
	@echo "• Stop & Remove services: make clean"
	@echo "• Help: make help"
	@echo "============================================"

# Da informacion general del estado del proyecto
status:
	@echo "\n📊 [STATUS] Checking services state"
	@echo "----------- Images -------------"
#	@docker images --filter "reference=inception_*"
	@docker images
	@echo "\n----------- Containers -----------"
#	@docker ps -a --filter "name=inception_"
	@docker ps -a
	@echo "\n----------- Networks ------------"
#	@docker network ls --filter "name=inception_"
	@docker network ls
	@echo "\n--- Volumes (into containers) ----"
#	@docker volume ls --filter "name=inception_"
	@docker volume ls
	@echo "\n------ Persistent Volumes ------"
		@echo "DRIVER	VOLUME NAME"
	@if [ -d "$(DB_DIR)" ]; then \
		echo "host	$(DB_DIR)"; \
	fi
	@if [ -d "$(WP_DIR)" ]; then \
		echo "host	$(WP_DIR)\n"; \
	fi
	@echo "\n---------- Disk Usage ----------"
	@docker system df

# Lanzo un build (sin -d detached) para tener los contenedores en primer plano y ver los logs en consola
debug:
	@$(COMPOSE) up --build

clean:
	@$(COMPOSE) down
	@echo "[CLEAN] Containers and network removed successfully (PERSISTENT DATA NOT AFECTED)"

fclean: clean
#	Aseguro que los contenedores están detenidos, liberan los volúmenes y los elimino.
	@if [ -d "$(MYDATA_DIR)" ]; then \
		echo "[FCLEAN] 🧹 Removing full persistent data directory $(MYDATA_DIR) with sudo..."; \
		sudo rm -rf $(MYDATA_DIR); \
	else \
		echo "[FCLEAN] No persistent data directory found at $(MYDATA_DIR)."; \
	fi
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true
#	'-' al inicio: ignora errores en los comandos criticos
	@echo "[FCLEAN] Removed intern volumes succesfully."
	@echo "[FCLEAN] Removing ALL project resources"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "[FCLEAN] Removing SSL certificates"
	@-rm -rf $(SSL_DIR) 2>/dev/null || true
	@docker builder prune
	@echo "[FCLEAN]🧹🧹🧹 Removed ALL build CACHE."

re: fclean all status

# ============= Help ============ #

help:
	@echo "\n🚀 Inception Project Makefile Help"
	@echo "make all          Build and start all services (alias for make build)"
	@echo "make certs        Generate SSL certificates only"
	@echo "make status       Show all containers' info"
	@echo "make clean        Stop & Remove containers and network ('docker-compose down')"
	@echo "make fclean       Full cleanup (containers, network, images, ALL volumes, ssl certs, ALL images cache)"
	@echo "make re           Cleanup everything and Rebuild"

.PHONY: all setup build down status clean fclean re help

verify-db:
	@echo "\n🔍 Verifying MariaDB secrets and database setup..."
	@container=$$(docker ps --filter "name=inception-mariadb" --format "{{.Names}}"); \
	if [ -z "$$container" ]; then \
		echo "❌ MariaDB container is not running."; \
		exit 1; \
	fi; \
	echo "✅ Found container: $$container"; \
	echo "📁 Checking mounted secrets..."; \
	docker exec -i $$container bash -c ' \
		for file in db_user db_password db_root_password; do \
			if [ ! -f /run/secrets/$$file ]; then \
				echo "❌ Missing /run/secrets/$$file"; \
				exit 1; \
			else \
				echo "✅ /run/secrets/$$file found"; \
			fi; \
		done'; \
	echo "📜 Checking init-db.sql content..."; \
	docker exec -i $$container grep -q "$$(cat secrets/db_user.txt)" /docker-entrypoint-initdb.d/init-db.sql && \
		echo "✅ User exists in init-db.sql" || \
		{ echo "❌ User not found in init-db.sql"; exit 1; }; \
	echo "🔐 Attempting MySQL login as WordPress user..."; \
	password=$$(cat secrets/db_password.txt); \
	user=$$(cat secrets/db_user.txt); \
	docker exec -i $$container mysql -u $$user -p$$password -e "SHOW DATABASES;" >/dev/null 2>&1 && \
		echo "✅ Login successful as $$user" || \
		echo "❌ Failed to login with provided credentials"

