#  🐳 Project: Inception

---


## Descripción


**Inception** es un proyecto de 42Barcelona cuyo objetivo es desplegar una infraestructura
completa utilizando **Docker** y **Docker Compose**, dentro de una máquina virtual.
 La arquitectura final replica un entorno real donde distintos servicios (NGINX, WordPress,
 MariaDB, etc.) se contienen y comunican entre sí de forma segura, mantenible y escalable.

---


## Arquitectura del Proyecto

Este proyecto contiene los siguientes servicios desplegados en contenedores Docker independientes:

- **NGINX**
  - Servidor web como punto de entrada único.
  - Configurado con certificados TLS para conexiones seguras vía HTTPS (TLSv1.2 y TLSv1.3).
  - Reenvía tráfico a WordPress.

- **WordPress (con PHP-FPM)**
  - CMS totalmente funcional y personalizado.
  - Desplegado sin NGINX, con PHP-FPM.
  - Almacenado en volumen persistente.

- **MariaDB**
  - Base de datos que alimenta a WordPress.
  - Inicializado con root y un usuario dedicado.
  - Volumen persistente para mantener la integridad de los datos.

- **Docker Network**
  - Todos los contenedores están conectados mediante una red bridge personalizada.

- **Volúmenes persistentes**
  - `/home/<login>/data/wordpress`: archivos del sitio WordPress.
  - `/home/<login>/data/mariadb`: datos de la base de datos.

---


## Seguridad y Buenas Prácticas

- Solo se expone el puerto **443** en NGINX (HTTPS).
- Las versiones de TLS anteriores a 1.2 están deshabilitadas.
- El nombre del usuario administrador de WordPress evita las palabras prohibidas como
`admin`, `administrator`, etc.
- Las credenciales se gestionan mediante variables de entorno y archivos secretos (`.env`,
`secrets/`).
- **Importante**: Aunque `.env` y `secrets/` se incluyen en este repositorio con fines
didácticos, en un entorno real **nunca deben almacenarse ni versionarse públicamente**.

---


## Bonus implementados

- **Adminer**
  - Interfaz web ligera para gestionar la base de datos MariaDB.
  - Accesible desde el navegador para inspección y consultas SQL.

- **Web estática**
  - Sitio estático personalizado (sin PHP) desplegado en un contenedor propio.
  - Ideal para mostrar un CV o portfolio simple en HTML/CSS/JS.

---


## 🚀 Instalación y Uso

Para construir y lanzar la infraestructura, simplemente ejecuta:

```bash
make all
````

Este comando realizará lo siguiente:

* Construirá todas las imágenes Docker necesarias usando los Dockerfiles proporcionados.
* Levantará todos los contenedores definidos en `docker-compose.yml`.
* Configurará la red y montará los volúmenes correspondientes.

Para comprobar el estado actual de la infraestructura, incluyendo las **imágenes creadas, contenedores en ejecución y volúmenes montados**, puedes usar:

```bash
make status
```

Este comando es útil para verificar que todo está funcionando correctamente, especialmente durante el desarrollo o antes de las pruebas.


---


## 🌍 Acceso al Proyecto

Una vez levantados los servicios, puedes acceder a:

* Sitio principal de WordPress:
  `https://<login>.42.fr`

* Web estática (bonus):
  `https://miwebestatica.42.fr` 

* Adminer (gestor de base de datos):
  `https://adminer.42.fr/adminer`

> Sustituye `<login>` por tu usuario real de 42. El dominio debe estar configurado en
> tu `/etc/hosts` apuntando a tu IP local.

---


## 📁 Estructura del Proyecto

```
.
├── .gitignore
├── Makefile
├── secrets
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── db_user.txt
│   ├── wp_admin_email.txt
│   ├── wp_admin_password.txt
│   ├── wp_admin_user.txt
│   ├── wp_user_email.txt
│   ├── wp_user_password.txt
│   └── wp_user.txt
└── srcs
    ├── docker-compose.yml
    ├── .env
    └── requirements
        ├── adminer
        │   └── Dockerfile
        ├── mariadb
        │   ├── conf
        │   │   └── 50-server.cnf
        │   ├── Dockerfile
        │   ├── .dockerignore
        │   └── tools
        │       ├── entrypoint.sh
        │       └── init-db.sql
        ├── nginx
        │   ├── conf
        │   │   ├── default.conf
        │   │   └── nginx.conf
        │   ├── Dockerfile
        │   └── .dockerignore
        ├── static-website
        │   ├── conf
        │   │   └── nginx.conf
        │   ├── Dockerfile
        │   └── html
        │       ├── index.html
        │       └── style.css
        └── wordpress
            ├── Dockerfile
            ├── .dockerignore
            └── tools
                └── entrypoint.sh

```

---


## Notas Técnicas

* Sistema operativo base: Debian 12 (bookworm).
* Todas las imágenes Docker están construidas manualmente desde Debian 11 (bullseye).
* No se han utilizado imágenes preconstruidas desde Docker Hub, en cumplimiento con las
* normas del proyecto.

---


## Autor

Proyecto realizado por **jocuni-p**
Escuela 42Barcelona
Julio 2025
