#!/bin/bash
# Uso: bash Automatizaciones_Instalar_Zabbix.sh <MYSQL_ROOT_PASS> <ZBX_DB_PASS>

set -euo pipefail

MYSQL_ROOT_PASS="${1:-changeme_mysql_root}"
ZBX_DB_PASS="${2:-changeme_zabbix_pass}"

export DEBIAN_FRONTEND=noninteractive

# Instala dependencias y repositorio Zabbix
apt-get update -y
apt-get install -y wget gnupg2 lsb-release apache2 mysql-server

wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu24.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu24.04_all.deb
apt-get update -y
apt-get install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

# Configura MySQL root y crea la base de datos de Zabbix
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASS}'; FLUSH PRIVILEGES;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS zabbix character set utf8mb4 collate utf8mb4_bin;"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY '${ZBX_DB_PASS}';"
mysql -u root -p"${MYSQL_ROOT_PASS}" -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost'; FLUSH PRIVILEGES;"

# Buscar el SQL de inicialización dondequiera que esté
SQL_PATH=$(find /usr/share/doc -name create.sql.gz | head -n 1)
if [ -f "$SQL_PATH" ]; then
  zcat "$SQL_PATH" | mysql -u root -p"${MYSQL_ROOT_PASS}" zabbix
else
  echo "ERROR: No se encontró create.sql.gz de Zabbix para crear la base de datos." >&2
  exit 1
fi

# Configura zabbix_server.conf con la contraseña
sed -i "s/# DBPassword=/DBPassword=${ZBX_DB_PASS}/" /etc/zabbix/zabbix_server.conf

# Inicia y habilita servicios
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

echo "Zabbix instalado correctamente. Acceso web: http://<TU_IP>/zabbix"
