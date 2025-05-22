---

# DevOps Day Medellín 2025 🚀

## Índice

1.  [Configurar IP elástica y DNS](#configurar-ip-elástica-y-dns) 🌐
2.  [Configurar instancia EC2 en AWS](#configurar-instancia-ec2-en-aws) ☁️
3.  [Infraestructura como código (Terraform)](#infraestructura-como-código-terraform) 🏗️
4.  [Gestión de usuarios y grupos](#gestión-de-usuarios-y-grupos) 🧑‍🤝‍🧑
5.  [Creación de scripts y permisos](#creación-de-scripts-y-permisos) 📜
6.  [Configurar Nginx](#configurar-nginx) ⚙️
7.  [Clonar repositorio de GitHub](#clonar-repositorio-de-github) 🐙
8.  [Desplegar aplicación con uWSGI](#desplegar-aplicación-con-uwsgi) 🚀
9.  [Conectar uWSGI con Nginx](#conectar-uwsgi-con-nginx) 🔗
10. [Probar aplicación web](#probar-aplicación-web) ✅
11. [Crear bases de datos RDS](#crear-bases-de-datos-rds) 🗄️

---

### Configurar IP elástica y DNS 🌐

1.  **Crear IP elástica en AWS.**
2.  **Asociar la IP elástica al DNS** en tu proveedor (por ejemplo, GoDaddy o Cloudflare).

---

### Configurar instancia EC2 en AWS ☁️

1.  Crear una instancia EC2.
2.  Elegir distribución Linux: **Ubuntu**.
3.  Asociar un rol IAM con permisos de acceso a **Systems Manager**.
4.  Conectarse a la instancia vía **SSH** usando una llave privada.
5.  Asignar permisos seguros a la llave privada:

    ```bash
    chmod 400 <nombre_llave>.pem
    ```

---

### Infraestructura como código (Terraform) 🏗️

1.  Instalar **Terraform**.
2.  En el archivo `main.tf` se encuentran los servicios de AWS configurados para desplegar la instancia EC2.
3.  Desde el directorio `Infraestructura`, ejecutar:

    ```bash
    terraform init
    terraform apply
    ```

---

### Gestión de usuarios y grupos 🧑‍🤝‍🧑

*   **Crear usuario con directorio home:**

    ```bash
    sudo useradd -m jhorman
    ```

*   **Crear usuario con bash como shell por defecto:**

    ```bash
    sudo useradd -m jhorman -s /bin/bash
    ```

*   **Eliminar usuario y su directorio:**

    ```bash
    sudo userdel -r jhorman
    ```

*   **Asignar contraseña al usuario:**

    ```bash
    sudo passwd jhorman
    ```

*   **Obtener ayuda sobre un comando:**

    ```bash
    useradd --help
    man useradd
    ```

*   **Cambiar de usuario:**

    ```bash
    su jhorman
    ```

*   **Agregar usuario a un grupo (por ejemplo, sudo):**

    ```bash
    sudo usermod -aG sudo jhorman
    ```

*   **Ver usuarios en el grupo sudo:**

    ```bash
    getent group sudo
    ```

---

### Creación de scripts y permisos 📜

*   **Crear un script para instalar paquetes:**

    ```bash
    nano script.sh
    ```

    Pega el siguiente contenido:

    ```bash
    #!/bin/bash
    sudo apt update
    sudo apt upgrade -y
    sudo apt install nginx -y
    sudo apt install certbot python3-certbot-nginx -y
    sudo apt install uwsgi uwsgi-plugin-python3 -y
    ```

*   **Verificar permisos del script:**

    ```bash
    ls -l script.sh
    ```

*   **Asignar permisos de ejecución al propietario:**

    ```bash
    chmod u+x script.sh
    ```

*   **Ejecutar el script:**

    ```bash
    ./script.sh
    ```

---

### Configurar Nginx ⚙️

*   **Crear archivo de configuración** en `/etc/nginx/sites-available/cafecloud.xyz`:

    ```nginx
    server {
        listen 80;
        server_name cafecloud.xyz;

        location / {
            return 200 "DevOps Day Medellin 2025";
            add_header Content-Type text/plain;
        }
    }
    ```

*   **Crear enlace simbólico** en `/etc/nginx/sites-enabled`:

    ```bash
    sudo ln -s /etc/nginx/sites-available/cafecloud.xyz /etc/nginx/sites-enabled/
    ```

*   **Probar configuración y reiniciar Nginx:**

    ```bash
    sudo nginx -t
    sudo systemctl restart nginx
    ```

*   **Configurar certificado SSL/TLS con Certbot:**

    ```bash
    sudo certbot --nginx
    ```

---

### Clonar repositorio de GitHub 🐙

*   **Mover el repositorio al home del usuario:**

    ```bash
    sudo mv bookstore-python-flask /home/jhorman
    ```

*   **Cambiar el propietario del repositorio:**

    ```bash
    sudo chown -R jhorman:jhorman /home/jhorman/bookstore-python-flask
    ```

*   **Instalar dependencias:**

    ```bash
    cd /home/jhorman/bookstore-python-flask
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

---

### Desplegar aplicación con uWSGI 🚀

*   **Usar tmux para múltiples terminales:**

    *   Iniciar tmux: `tmux`
    *   Dividir panel: `Ctrl + b, %`
    *   Cambiar de panel: `Ctrl + b`, flecha

*   **Crear archivo de configuración uWSGI** en `/etc/uwsgi/apps-available/cafecloud.ini`:

    ```ini
    [uwsgi]
    chdir = /home/jhorman/bookstore-python-flask
    home = /home/jhorman/bookstore-python-flask/venv
    module = app:app
    plugins = python3
    master = true
    processes = 4
    socket = /tmp/cafecloud.sock
    ```

*   **Crear enlace simbólico en apps-enabled:**

    ```bash
    sudo ln -s /etc/uwsgi/apps-available/cafecloud.ini /etc/uwsgi/apps-enabled/
    ```

*   **Ver procesos activos:**

    ```bash
    htop
    ```

*   **Ver logs de uWSGI:**

    ```bash
    sudo less /var/log/uwsgi/app/cafecloud.log
    ```

*   **Dar permisos a www-data sobre el entorno virtual:**

    ```bash
    sudo chown -R jhorman:www-data /home/jhorman/bookstore-python-flask/venv
    sudo chmod -R 755 /home/jhorman/bookstore-python-flask/venv
    sudo chmod 755 /home/jhorman
    sudo chmod 755 /home/jhorman/bookstore-python-flask
    ```

---

### Conectar uWSGI con Nginx 🔗

*   **Editar el archivo de configuración de Nginx** para el dominio y agregar:

    ```nginx
    location / {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/cafecloud.sock;
    }
    ```

*   **Validar configuración y reiniciar servicios:**

    ```bash
    sudo nginx -t
    sudo systemctl restart nginx
    sudo systemctl restart uwsgi
    ```

---

### Probar aplicación web ✅

*   Accede a la aplicación desde el navegador usando el dominio configurado en el DNS.

---

### Crear bases de datos RDS 🗄️

*   **Asignar nombre a la instancia RDS en `/etc/hosts`:**

    1.  Obtener la IP de la instancia RDS:

        ```bash
        dig rds-endpoint
        ```

    2.  Editar `/etc/hosts` y agregar:

        ```
        127.0.0.1   localhost
        192.168.3.125   db-rds
        ```

*   **Conectarse a la base de datos:**

    ```bash
    mysql -u admin -p --host db-rds
    ```

---