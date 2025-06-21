#!/bin/bash
# Uso: bash Automatizaciones_Instalar_Nextcloud.sh <MYSQL_ROOT_PASS> <NC_DB> <NC_DB_USER> <NC_DB_PASS> <SITE_URL> <NC_ADMIN> <NC_ADMIN_PASS>

set -euo pipefail

MYSQL_ROOT_PASS="${1:-changeme_rootpass}"
NC_DB="${2:-nextcloud_db}"
NC_DB_USER="${3:-nc_user}"
NC_DB_PASS="${4:-NcUserPassw0rd!}"
SITE_URL="${5:-http://localhost}"
NC_ADMIN="${6:-ncadmin}"
NC_ADMIN_PASS="${7:-NcAdminPassw0rd!}"

export DEBIAN_FRONTEND=noninteractive

# Instala LAMP stack y dependencias para Nextcloud
apt-get update -y
apt-get upgrade -y
apt-get install -y apache2 php php-mysql php-gd php-curl php-xml php-zip php-mbstring php-intl php-bcmath php-gmp php-imagick libapache2-mod-php mysql-server unzip wget curl

# Configura MySQL
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${NC_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS '${NC_DB_USER}'@'localhost' IDENTIFIED BY '${NC_DB_PASS}';"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON ${NC_DB}.* TO '${NC_DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

# Instala Nextcloud (última versión)
cd /tmp
NEXTCLOUD_VERSION=$(curl -s https://nextcloud.com/changelog/ | grep -Eo "Nextcloud [0-9]+\.[0-9]+\.[0-9]+" | head -n1 | awk '{print $2}')
wget -q "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.zip" || wget -q "https://download.nextcloud.com/server/releases/latest.zip"
unzip -oq nextcloud-*.zip
rm -rf /var/www/html/*
cp -r nextcloud/* /var/www/html/
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Habilita módulos necesarios de Apache
a2enmod rewrite headers env dir mime setenvif ssl

# Reinicia Apache para cargar módulos
systemctl restart apache2

# Instala OCC: usa el propio binario php de la VM
sudo -u www-data php /var/www/html/occ maintenance:install \
  --database "mysql" \
  --database-name "${NC_DB}" \
  --database-user "${NC_DB_USER}" \
  --database-pass "${NC_DB_PASS}" \
  --admin-user "${NC_ADMIN}" \
  --admin-pass "${NC_ADMIN_PASS}" \
  --data-dir "/var/www/html/data"

# Ajusta la URL de confianza para la instancia
sudo -u www-data php /var/www/html/occ config:system:set trusted_domains 1 --value="${SITE_URL#http://}"

# (Opcional) Sube el límite de tamaño de archivo para subida
sed -i 's/post_max_size = .*/post_max_size = 2048M/' /etc/php/*/apache2/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 2048M/' /etc/php/*/apache2/php.ini

systemctl reload apache2

echo "Nextcloud instalado correctamente en ${SITE_URL}"
echo "Accede con usuario: ${NC_ADMIN} y contraseña: ${NC_ADMIN_PASS}"
