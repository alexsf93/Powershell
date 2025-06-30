#!/bin/bash
set -e

N8N_PORT=5678

# Instalar dependencias
apt-get update -y
apt-get install -y curl build-essential nginx

# Instalar Node.js 20.x y n8n
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g n8n

# Crear usuario dedicado para n8n
useradd -m -s /bin/bash n8n || true
mkdir -p /home/n8n/.n8n
chown -R n8n:n8n /home/n8n/.n8n

# Crear/actualizar servicio systemd para n8n
cat > /etc/systemd/system/n8n.service <<EOF
[Unit]
Description=n8n automation
After=network.target

[Service]
Type=simple
User=n8n
ExecStart=/usr/bin/n8n
Restart=on-failure
Environment=PATH=/usr/bin:/usr/local/bin N8N_HOST=localhost N8N_PORT=5678 N8N_PROTOCOL=https N8N_SECURE_COOKIE=true
WorkingDirectory=/home/n8n

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable n8n
systemctl restart n8n

# Obtener la IP pública para el CN del certificado
PUBIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || hostname)

# Generar certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/n8n-selfsigned.key \
  -out /etc/ssl/certs/n8n-selfsigned.crt \
  -subj "/CN=$PUBIP"

# Configuración nginx reverse proxy para HTTPS
cat > /etc/nginx/sites-available/n8n <<EOF
server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/ssl/certs/n8n-selfsigned.crt;
    ssl_certificate_key /etc/ssl/private/n8n-selfsigned.key;

    location / {
        proxy_pass http://localhost:${N8N_PORT};
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_http_version 1.1;
    }
}

server {
    listen 80;
    server_name _;
    return 301 https://\$host\$request_uri;
}
EOF

ln -sf /etc/nginx/sites-available/n8n /etc/nginx/sites-enabled/n8n
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Abrir puertos en firewall local si aplica
if command -v ufw >/dev/null 2>&1; then
    ufw allow 'Nginx Full'
fi

echo ""
echo "=========================================="
echo " n8n ya está instalado y accesible en:"
echo "   https://$PUBIP/"
echo " (Acepta el certificado autofirmado en tu navegador)"
echo "=========================================="
