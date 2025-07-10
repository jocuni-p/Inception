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

#	NGINX necesita un certificado SSL para proteger el tunel de comunicacion de HTTP.
#	Para poder hacer el proyecto generare un certificado SSL autofirmado (test para desarrollo)
#	Asegura que el directorio para los certificados exista antes de generarlos, sino lo crea
$(SSL_DIR):
	@echo "[SSL] Creating SSL directory structure"
	@mkdir -p $@

#	Creara los 2 targets. 
#	El '|' verifica solo que exista la dependencia. No reconstruye si esta cambia.
#	Crea un certificado autofirmado, sin contrasenya, valido por 1 anyo, 
#	con la clave rsa de 2048 bits, rutas de salida y establece mi dominio como sujeto.
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

#	Primera vez que arranco el proyecto
all: certs setup build status

#	Genera el certificado
certs: $(SSL_KEY) $(SSL_CRT)

#	Crea e inicializa los volumenes locales persistentes y comprueba si el dominio esta en /etc/hosts
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

#	Construye y levanta los containers en segundo plano (detached)
#	up: Levanta los servicios definidos en el docker-compose.yml.
#	--build: Reconstruye las imágenes Docker (antes de iniciar los 
#	 contenedores) si hubo cambios en los Dockerfiles o dependencias.
build:
	@echo "[BUILD] Building containers with TLS 1.3"
	@$(COMPOSE) up -d --build
	@echo "\n✅ [SUCCESS] Inception project is running!"
	@echo "============================================"
	@echo "• Access: https://$(DOMAIN)"
	@echo "• Help: make help"
	@echo "============================================"


#	 Crea y levanta containers sin reconstruir las imagenes (util despues de un clean)
up:
	@$(COMPOSE) up -d


#	Detiene y elimina los contenedores, conservando las imagenes
clean:
	@$(COMPOSE) down
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true
	@echo "[CLEAN] Containers, volumes and network removed successfully (IMAGES AND PERSISTENT DATA NOT AFECTED)"

fclean: clean
	@if [ -d "$(MYDATA_DIR)" ]; then \
		echo "[FCLEAN] 🧹 Removing full persistent data directory $(MYDATA_DIR) with sudo..."; \
		sudo rm -rf $(MYDATA_DIR); \
	else \
		echo "[FCLEAN] No persistent data directory found at $(MYDATA_DIR)."; \
	fi
	@-docker volume rm inception_db_vol inception_wp_vol 2>/dev/null || true
#	'-' al inicio: ignora errores en los comandos criticos
	@echo "[FCLEAN] Removing images, volumes and orphan resources"
	@$(COMPOSE) down --rmi all --volumes --remove-orphans
	@echo "[FCLEAN] Removing SSL certificates"
	@-rm -rf $(SSL_DIR) 2>/dev/null || true
	@docker builder prune
	@echo "[FCLEAN]🧹🧹🧹 Removed ALL build CACHE."

re: fclean all status

help:
	@echo "\n🚀 Inception Project Makefile Help"
	@echo "make all          Build and start the whole system from zero for the first time"
	@echo "make certs        Generate SSL certificates"
	@echo "make setup	 Set up persistent volumes and check domain usability"
	@echo "make build	 ReBuild images if some Dockerfile or dependency has changed and up containers"
	@echo "make up		 Up containers from existing images"
	@echo "make status       Show all containers' info"
	@echo "make clean        Stop & Remove containers, network and intern volumes"
	@echo "make fclean       Full cleanup (containers, network, images, ALL volumes, ssl certs, ALL images cache)"
	@echo "make re           Cleanup everything and Rebuild from zero"
	@echo "make logs         Show all containers logs"
	@echo "make test         Test every container functioning"


.PHONY: all certs setup build up clean fclean re status help logs test


# ============= Debug ============ #

#	Da informacion general del estado del proyecto
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


logs:
	@$(COMPOSE) logs



# ============ Testing ========== #

test:	verify-db verify-wp verify-nginx


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


verify-wp:
	@echo "==========================================="
	@echo "\n🔍 Verifying WordPress container setup..."
	@container=$$(docker ps --filter "name=inception-wordpress" --format "{{.Names}}"); \
	if [ -z "$$container" ]; then \
		echo "❌ WordPress container is not running."; \
		exit 1; \
	fi; \
	echo "✅ Found container: $$container"; \
	echo "📁 Checking mounted secrets..."; \
	docker exec -i $$container bash -c ' \
		for file in wp_user wp_user_password; do \
			if [ ! -f /run/secrets/$$file ]; then \
				echo "❌ Missing /run/secrets/$$file"; \
				exit 1; \
			else \
				echo "✅ /run/secrets/$$file found"; \
			fi; \
		done'; \
	echo "🌐 Verifying connection to MariaDB from WordPress..."; \
	db_user=$$(cat secrets/db_user.txt); \
	db_password=$$(cat secrets/db_password.txt); \
	docker exec -i $$container bash -c ' \
		mysql -h mariadb -u'$$db_user' -p'$$db_password' -e "SHOW DATABASES;"' >/dev/null 2>&1 && \
		echo "✅ WordPress can connect to MariaDB" || \
		echo "❌ WordPress failed to connect to MariaDB"


verify-nginx:
	@echo "==========================================="
	@echo "\n🔍 Verifying Nginx (HTTPS) and WordPress availability..."
	@container=$$(docker ps --filter "name=inception-nginx" --format "{{.Names}}"); \
	if [ -z "$$container" ]; then \
		echo "❌ Nginx container is not running."; \
		exit 1; \
	fi; \
	echo "✅ Found container: $$container"; \
	echo "⏳ Waiting for WordPress to be available over HTTPS..."
	@for i in $$(seq 1 15); do \
		status=$$(curl -ks -o /dev/null -w "%{http_code}" https://localhost/wp-login.php); \
		if echo "$$status" | grep -qE "200|302"; then \
			echo "✅ WordPress is accessible over HTTPS via Nginx (HTTP $$status)\n"; \
			exit 0; \
		else \
			echo "Attempt $$i: Not ready (HTTP $$status), retrying..."; \
			sleep 2; \
		fi; \
	done; \
	echo "\n❌ WordPress not accessible over HTTPS after multiple attempts.\n"; \
	exit 1

