#########################################################################################
#   Instalador Headless de Nextcloud para Ubuntu 24.04 LTS
#
#   Este script automatiza la instalación de Nextcloud (última versión estable) sobre
#   un stack LAMP en Ubuntu 24.04 LTS. Permite ejecución desatendida, integración en
#   automatizaciones cloud y paso de credenciales por parámetros.
#
#   -----------------------------------------------------------------------------
#
#   Características:
#   - Instalación 100% automatizada de Apache, PHP, MariaDB/MySQL y Nextcloud.
#   - Creación automática de base de datos, usuario y configuración de Nextcloud.
#   - Permite definir credenciales y dominio por argumentos.
#   - Optimizado para laboratorios, despliegues cloud y pipelines CI/CD.
#
#   Requisitos:
#   - Ubuntu Server 24.04 LTS limpio (sin Nextcloud previamente instalado).
#   - Ejecutar como root o con sudo.
#   - Acceso a Internet para descargar paquetes y Nextcloud.
#
#   Uso:
#       bash Automatizaciones_Instalar_Nextcloud.sh [mysql_root_pass] [nc_db] [nc_db_user] [nc_db_pass] [site_url] [nc_admin] [nc_admin_pass]
#     - [mysql_root_pass]  → Contraseña root de MySQL/MariaDB
#     - [nc_db]            → Nombre de base de datos para Nextcloud
#     - [nc_db_user]       → Usuario de base de datos para Nextcloud
#     - [nc_db_pass]       → Contraseña de base de datos para Nextcloud
#     - [site_url]         → URL pública del sitio (por ejemplo, http://IP)
#     - [nc_admin]         → Usuario administrador Nextcloud
#     - [nc_admin_pass]    → Contraseña administrador Nextcloud
#
#   Acceso tras instalación:
#     - Web:      http://<IP-DE-TU-VM>/
#     - Usuario admin Nextcloud:    <nc_admin>
#     - Contraseña admin Nextcloud: <nc_admin_pass>
#
#   Advertencia:
#     Cambia las contraseñas y parámetros por defecto si el entorno es accesible
#     públicamente o es productivo.
#
#   Autor: Alejandro Suárez (@alexsf93)
#########################################################################################
#!/bin/bash

set -euxo pipefail
exec > >(tee /tmp/nextcloud_install_stdout.log)
exec 2> >(tee /tmp/nextcloud_install_stderr.log >&2)

MYSQL_ROOT_PASS="${1:-changeme_rootpass}"
NC_DB="${2:-nextcloud_db}"
NC_DB_USER="${3:-nc_user}"
NC_DB_PASS="${4:-NcUserPassw0rd!}"
SITE_URL="${5:-http://localhost}"
NC_ADMIN="${6:-ncadmin}"
NC_ADMIN_PASS="${7:-NcAdminPassw0rd!}"

export DEBIAN_FRONTEND=noninteractive

echo "---- Instalando LAMP y dependencias para Nextcloud ----"
apt-get update -y
apt-get upgrade -y
apt-get install -y apache2 mariadb-server \
 php php-mysql php-gd php-curl php-xml php-zip php-mbstring php-intl php-bcmath php-gmp php-imagick libapache2-mod-php wget unzip curl

echo "---- Configurando MariaDB/MySQL ----"
service mysql start
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS ${NC_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${NC_DB_USER}'@'localhost' IDENTIFIED BY '${NC_DB_PASS}';
GRANT ALL PRIVILEGES ON ${NC_DB}.* TO '${NC_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "---- Descargando y preparando Nextcloud ----"
cd /tmp
wget -q https://download.nextcloud.com/server/releases/latest.zip
unzip -oq latest.zip

# Limpia y recrea /var/www/html para Nextcloud
if [ -d /var/www/html ]; then
    rm -rf /var/www/html/*
else
    mkdir -p /var/www/html
fi

cp -r nextcloud/* /var/www/html/
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

echo "---- Habilitando módulos necesarios de Apache ----"
a2enmod rewrite headers env dir mime setenvif ssl

echo "---- Reiniciando Apache ----"
systemctl restart apache2

echo "---- Instalando Nextcloud en modo headless ----"
sudo -u www-data php /var/www/html/occ maintenance:install \
  --database "mysql" \
  --database-name "${NC_DB}" \
  --database-user "${NC_DB_USER}" \
  --database-pass "${NC_DB_PASS}" \
  --admin-user "${NC_ADMIN}" \
  --admin-pass "${NC_ADMIN_PASS}" \
  --data-dir "/var/www/html/data"

# Ajustar trusted domain
DOMAIN=$(echo "$SITE_URL" | sed 's|http[s]*://||;s|/.*$||')
sudo -u www-data php /var/www/html/occ config:system:set trusted_domains 1 --value="$DOMAIN"

# (Opcional) Ajusta el tamaño máximo de archivos a 2GB
PHP_INI=$(php --ini | grep "Loaded Configuration" | awk '{print $4}')
sed -i 's/post_max_size = .*/post_max_size = 2048M/' $PHP_INI
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2048M/' $PHP_INI
systemctl reload apache2

echo "---- Estado de servicios ----"
systemctl status apache2 --no-pager || true
systemctl status mysql --no-pager || systemctl status mariadb --no-pager || true
php -v || true
echo "-----------------------------"

echo
echo "Nextcloud instalado correctamente en ${SITE_URL}"
echo "Accede con usuario: ${NC_ADMIN} y contraseña: ${NC_ADMIN_PASS}"
