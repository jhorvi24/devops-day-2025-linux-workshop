# devops-day-2025-linux-workshop

## Configurar DNS

- En AWS crear IP elástica.
- Asociar IP elástica a DNS


## Configure una instance en AWS

- Crear instance EC2
- Asociar rol IAM
- Conectar a la instancia a través de ssh
- Usar llave privada para conectarse
- Aplicar permisos
```bash
    chdmod 400
```

## Usuarios y Grupos de usuarios

- Crear un usuario
```bash
useradd jhorman
```

- Agregar usuarios a grupo sudo
```bash
usermod -G sudo -a jhorman
```

# Creación de scripts y permisos
- Crear un script para instalar diferentes paquetes
```bash
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install nginx -y
sudo apt install certbot python3-certbot-nginx -y
sudo apt install uwsgi uwsgi-plugin-python3 -y
sudo apt install python3-pip -y
sudo apt install python3-virtualenv
sudo apt install mariadb-server -y
```
- Revisar los permisos del script
```bash
ls -l
```
- Habilitar permisos de ejecución
```bash
sudo chmod +x script.sh 
```
- Ejecutar script
```bash
sudo ./script.sh
```
#Configurar nginx
- Crear archivo de configuración en la ruta /etc/nginx/sites-availables
```bash
server {
        listen 80;
        server_name cafecloud.xyz;

        location / {
                return 200 "Hola desde el archivo conf";
                add_header Content-Type text/plain;
        }
}
```
- Desde el directorio /etc/nginx/sites-enabled crear ruta simbólica 
```bash
sudo ln -s ../sites-available/cafecloud.xyz
```
- Ejecutar el siguiente comando para configurar certificado de seguridad SSL/TLS
```bash
sudo certbot --nginx
```

# Clonar repositorio de GitHub

- Instalar paquetes necesarios utilizando el archivo requirements.txt
```bash
python3 -m virtualenv venv
source venv/bin/activate
pip3 install -r requirements.txt

```

- Desplegar la aplicación web a través de uwsgi
- Utilizar tmux para trabajar con dos terminales y configurar el archivos de uwsgi:
```bash
tmux
```
```bash
ctrl + b, % 
```
```bash
ctrl + b, arrow key ()
```
- Crear el siguiente archivo en la ruta /etc/uwsgi/apps-available

```bash
[uwsgi]
chdir = /home/jhorman/bookstore-app
home = ../venv
module = app:app
plugins = python3
master = true
processes = 4
socket = /tmp/cafecloud.sock
```
- Crear el enlace simbólico desde el directorio /etc/uwsgi/apps-enabled
```bash
sudo ln -s ../apps-available/cafecloud.ini .
```
- uwsgi es controlado por el usuario www-data. Se debe dar permiso para que este usuario acceda al entorno virtual del proyecto
```bash
sudo chown -R jhorman:www-data /home/jhorman/bookstore-app/venv
```
- Habilitar permisos:
```bash
sudo chmod -R 755 /home/jhorman/bookstore-app/venv
```
```bash
sudo chmod 755 /home/jhorman
```
```bash
sudo chmod 755 /home/jhorman/bookstore-app
```

# Conectar uwsgi con nginx

- Desde el archivo de configuración de nginx relacionado con el dominio, agregar lo siguiente:

```bash
location / {
        include uwsgi_params;
        uwsgi_pass unix:/tmp/cafecloud.sock;
};
```
- Validar configuracion y reiniciar servicio
```bash
sudo nginx -t 
sudo service nginx restart
sudo service uwsgi restart
```
## Probar aplicación web a través del DNS


## Crear bases de datos RDS
- Utilizando el archivo /etc/hosts dar un nombre a la instancia RDS
- Obtener la dirección IP de la instancia RDS
```bash
dig rds-endpoint
```
- Editar el archivo /etc/hosts
```bash
127.0.0.1 localhost
192.168.3.125 db-rds
```
- Conectarse a la base de datos
```bash
mysql -u root -p --host db-rds
```