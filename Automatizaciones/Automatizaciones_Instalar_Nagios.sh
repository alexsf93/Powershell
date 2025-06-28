#!/bin/bash

#########################################################################################
#   Instalador headless de Nagios Core en Ubuntu 24.04 LTS
#   Parámetros:
#      $1 - usuario admin Nagios (default: nagiosadmin)
#   Uso:
#      bash Automatizaciones_Instalar_Nagios.sh [usuario]
#########################################################################################

set -euo pipefail

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # Sin color

echo -e "${BOLD}Iniciando instalación headless de Nagios Core...${NC}"

# Parámetros
NAGIOS_ADMIN=${1:-nagiosadmin}
NAGIOS_PASS="Nagios123!"  # Puedes cambiar esta contraseña o parametrizarla

# Actualización de paquetes
echo -e "${CYAN}Actualizando sistema...${NC}"
apt update && apt upgrade -y

# Instalando dependencias
echo -e "${CYAN}Instalando dependencias necesarias...${NC}"
apt install -y autoconf gcc libapache2-mod-php php unzip apache2 libgd-dev libmcrypt-dev libssl-dev daemon wget bc gawk dc build-essential snmp libnet-snmp-perl gettext

# Creando usuario y grupo Nagios
useradd nagios || true
usermod -a -G nagios www-data

# Descargando Nagios Core
NAGIOS_VERSION="4.5.2"
cd /tmp
echo -e "${CYAN}Descargando Nagios Core $NAGIOS_VERSION...${NC}"
wget -q https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-$NAGIOS_VERSION/nagios-$NAGIOS_VERSION.tar.gz
tar -xzf nagios-$NAGIOS_VERSION.tar.gz
cd nagios-$NAGIOS_VERSION

# Compilando e instalando Nagios
echo -e "${CYAN}Compilando Nagios Core...${NC}"
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
make install
make install-daemoninit
make install-commandmode
make install-config
make install-webconf

# Instalando plugin Nagios
echo -e "${CYAN}Descargando e instalando plugins de Nagios...${NC}"
cd /tmp
PLUGIN_VERSION="2.4.10"
wget -q https://github.com/nagios-plugins/nagios-plugins/releases/download/release-$PLUGIN_VERSION/nagios-plugins-$PLUGIN_VERSION.tar.gz
tar -xzf nagios-plugins-$PLUGIN_VERSION.tar.gz
cd nagios-plugins-$PLUGIN_VERSION
./configure
make
make install

# Configurando usuario web Nagios
echo -e "${CYAN}Configurando usuario web para Nagios...${NC}"
htpasswd -b -c /usr/local/nagios/etc/htpasswd.users "$NAGIOS_ADMIN" "$NAGIOS_PASS"

# Habilitar módulos y reiniciar Apache
echo -e "${CYAN}Habilitando CGI y reiniciando Apache...${NC}"
a2enmod cgi
systemctl enable apache2
systemctl restart apache2

# Iniciar Nagios y habilitar en el arranque
systemctl enable nagios
systemctl restart nagios

# Información final
IP_PUBLICA=$(curl -s http://checkip.amazonaws.com || hostname -I | awk '{print $1}')
echo -e "\n${GREEN}${BOLD}Nagios Core instalado correctamente.${NC}"
echo -e "${BLUE}Acceso web:${NC} ${YELLOW}http://${IP_PUBLICA}/nagios${NC}"
echo -e "${BLUE}Usuario web:${NC} ${YELLOW}${NAGIOS_ADMIN}${NC}"
echo -e "${BLUE}Contraseña web:${NC} ${YELLOW}${NAGIOS_PASS}${NC}\n"
echo -e "${CYAN}IMPORTANTE: Cambia la contraseña tras la primera conexión si es un entorno de producción.${NC}"

exit 0
