#!/bin/bash
# Automatizaciones_Instalar_Wazuh.sh
# Instalador automático de Wazuh 4.x (manager, dashboard, filebeat) en Ubuntu 22.04/24.04

set -euxo pipefail

echo "========== INSTALANDO WAZUH SERVER ALL-IN-ONE =========="
export DEBIAN_FRONTEND=noninteractive

# Actualiza el sistema
apt-get update -y
apt-get upgrade -y

# Instala dependencias necesarias
apt-get install -y curl apt-transport-https lsb-release gnupg2

# Añade repositorio de Wazuh
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor > /usr/share/keyrings/wazuh-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh-keyring.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list

# Instala Wazuh Manager, Filebeat, Wazuh Dashboard
apt-get update -y
apt-get install -y wazuh-manager filebeat wazuh-dashboard

# Habilita y arranca servicios
systemctl enable wazuh-manager filebeat wazuh-dashboard
systemctl restart wazuh-manager filebeat wazuh-dashboard

# Permite el puerto 5601 y 55000 en el firewall
if command -v ufw &>/dev/null; then
    ufw allow 5601/tcp
    ufw allow 55000/tcp
fi

# Contraseña admin por defecto: admin
echo "==============================================================="
echo "Wazuh instalado. Accede al Dashboard en https://<IP>:5601"
echo "Usuario: admin / Contraseña: admin"
echo "==============================================================="
