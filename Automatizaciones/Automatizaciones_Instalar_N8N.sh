#!/bin/bash
set -e

echo "===== Instalando Node.js y n8n ====="

# Dependencias básicas
apt-get update -y
apt-get install -y curl build-essential

# Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# n8n global
npm install -g n8n

# Crear usuario dedicado para n8n (más seguro)
useradd -m -s /bin/bash n8n || true
mkdir -p /home/n8n/.n8n
chown -R n8n:n8n /home/n8n/.n8n

# Crear servicio systemd para n8n
cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n automation
After=network.target

[Service]
Type=simple
User=n8n
ExecStart=/usr/bin/n8n
Restart=on-failure
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=/home/n8n

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable n8n
systemctl start n8n

# Abrir puerto en firewall local (por si acaso)
if command -v ufw >/dev/null 2>&1; then
    ufw allow 5678/tcp || true
fi

echo "===== n8n instalado y corriendo ====="
