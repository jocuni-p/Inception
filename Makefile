# Project configuration

#test
#
## =====================================================================
# NOTE:
# Due security reasons, the domain 'jocuni-p.42.fr' has already been
# inserted manually into the local '/etc/hosts' file to point to 127.0.0.1.
# Therefore, the Makefile does not modify the hosts file.
# Make sure this entry exists before running the project:
#
#     127.0.0.1 jocuni-p.42.fr
#
# =====================================================================
#
# Variables
PROJECT = inception
DOMAIN = jocuni-p.42.fr
MYDATA_DIR = /Users/joan/mydata # MacOS
# MYDATA_DIR = /home/jocuni-p/mydata # MVDebian
DB_DIR = $(MYDATA_DIR)/db_vol
WP_DIR = $(MYDATA_DIR)/wp_vol
COMPOSE = docker-compose -f srcs/docker-compose.yml -p $(PROJECT)

# Rules
all: build

setup:
	@echo "[SETUP] Creating volume directories in $(MYDATA_DIR)"
	@mkdir -p $(DB_DIR) $(WP_DIR)
#	@echo "[SETUP] Ensuring $(DOMAIN) is in /etc/hosts"
#	@grep -q "$(DOMAIN)" /etc/hosts || echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts > /dev/null
#	Busca si el dominio "jocuni-p.42.fr" esta presente en hosts. La -q es modo silencioso.
#	Si no lo esta, lo escribe y lo anyade a hosts con sudo (para tener permiso) tee.
#	Con > /dev/null suprimo la salida de tee, evitando impresion en consola

build: setup
	@echo "[BUILD] Building Docker images and starting containers"
	@$(COMPOSE) up -d --build #Con up arranco los servicios del docker-compose.yml

stop:
	@echo "[STOP] Stopping containers"
	@$(COMPOSE) stop

start:
	@echo "[START] Starting containers"
	@$(COMPOSE) start

down:
	@echo "[DOWN] Removing containers"
	@$(COMPOSE) down
	#Detiene la aplicacion y elimina containers, networks, creados por docker-compose up.
	#Forma limpia de cerrar y salir. Sin ninguna option No elimina imagenes ni volumenes.

clean: down
	@echo "[CLEAN] Removing project volumes and network"
	@docker volume rm $(PROJECT)_db_vol $(PROJECT)_wp_vol 2>/dev/null || true
	@docker network rm $(PROJECT)_inception 2>/dev/null || true
#	Con 2>/dev/null elimino cualquier mensaje de error.
#	Si no existen los volumenes, hay '|| true' para que no se pare el Makefile 

fclean: clean
	@echo "[FCLEAN] Removing project images"
	@docker images --filter=reference="$(PROJECT)_*" -q | xargs -r docker rmi 2>/dev/null || true

re: fclean all

.PHONY: all setup build stop start down clean fclean re

