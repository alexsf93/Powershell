#!/bin/bash
# Uso: bash install-wordpress.sh <MYSQL_ROOT_PASS> <WP_DB> <WP_USER> <WP_PASS>

set -euo pipefail

# --- INPUTS ---
MYSQL_ROOT_PASS="${1:-changeme_rootpass}"
WP_DB="${2:-wordpress_db}"
WP_USER="${3:-wp_user}"
WP_PASS="${4:-WpUserPassw0rd!}"

# --- Actualiza sistema y paquetes esenciales ---
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

apt-get install -y apache2 php php-mysql php-cli php-curl php-gd php-xml php-mbstring mysql-server curl wget unzip

# --- Configura MySQL root (solo si aún no tiene pass) ---
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"

# --- Prepara base de datos y usuario de WordPress ---
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS ${WP_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER IF NOT EXISTS '${WP_USER}'@'localhost' IDENTIFIED BY '${WP_PASS}';
GRANT ALL ON ${WP_DB}.* TO '${WP_USER}'@'localhost';
FLUSH PRIVILEGES;"

# --- Instala WordPress ---
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

rm -rf /var/www/html/*
cp -r wordpress/* /var/www/html/

# --- Permisos ---
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# --- Configura wp-config.php ---
cd /var/www/html
cp wp-config-sample.php wp-config.php

sed -i "s/database_name_here/${WP_DB}/" wp-config.php
sed -i "s/username_here/${WP_USER}/" wp-config.php
sed -i "s/password_here/${WP_PASS}/" wp-config.php

# --- Añade claves secretas únicas ---
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
sed -i "/AUTH_KEY/d;/SECURE_AUTH_KEY/d;/LOGGED_IN_KEY/d;/NONCE_KEY/d;/AUTH_SALT/d;/SECURE_AUTH_SALT/d;/LOGGED_IN_SALT/d;/NONCE_SALT/d" wp-config.php
echo "$SALT" >> wp-config.php

# --- Reinicia Apache ---
systemctl restart apache2

# --- (Opcional) Actualización no atendida ---
unattended-upgrade -d || true

echo "WordPress instalado correctamente en /var/www/html"
