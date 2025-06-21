#!/bin/bash
# Instalador Zabbix 6.4 para Ubuntu 24.04 headless

set -euo pipefail

MYSQL_ROOT_PASS="${1:-changeme_mysql_root}"
ZBX_DB_PASS="${2:-changeme_zabbix_pass}"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y wget curl gnupg2 lsb-release apache2 mysql-server

# Añadir el repositorio oficial de Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu24.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu24.04_all.deb
apt-get update -y
apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

# Configura MySQL root y prepara base de datos para Zabbix
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY '${ZBX_DB_PASS}';"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost'; FLUSH PRIVILEGES;"

# IMPORTA SOLO SCHEMA.SQL (ya no existe ni images ni data en Zabbix 6.4)
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u root -p"${MYSQL_ROOT_PASS}" zabbix

# Configura password de la DB en zabbix_server.conf
sed -i "s/# DBPassword=/DBPassword=${ZBX_DB_PASS}/" /etc/zabbix/zabbix_server.conf

# Arranca y habilita servicios
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

echo "===================================================================="
echo "Zabbix instalado correctamente. Accede vía navegador a:"
echo "  http://<TU_IP>/zabbix"
echo "Usuario inicial: Admin   Contraseña: zabbix"
echo "Base de datos MySQL root: $MYSQL_ROOT_PASS"
echo "Usuario MySQL zabbix: zabbix   Contraseña: $ZBX_DB_PASS"
echo "===================================================================="
