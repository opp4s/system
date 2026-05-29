#!/usr/bin/env bash
# Instala e configura Nginx + Certbot para api.zavycrm.com e chat.zavycrm.com
# Uso: sudo bash scripts/setup-nginx.sh
#
# Pré-requisito: DNS de api.zavycrm.com e chat.zavycrm.com apontando para esta VPS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Instalando Nginx e Certbot..."
apt-get update -qq
apt-get install -y nginx certbot python3-certbot-nginx

echo "==> Copiando configs do Nginx..."
cp "$PROJECT_DIR/nginx/api.zavycrm.com.conf"  /etc/nginx/sites-available/api.zavycrm.com
cp "$PROJECT_DIR/nginx/chat.zavycrm.com.conf" /etc/nginx/sites-available/chat.zavycrm.com

# Ativa os sites
ln -sf /etc/nginx/sites-available/api.zavycrm.com  /etc/nginx/sites-enabled/api.zavycrm.com
ln -sf /etc/nginx/sites-available/chat.zavycrm.com /etc/nginx/sites-enabled/chat.zavycrm.com

# Remove default se existir
rm -f /etc/nginx/sites-enabled/default

echo "==> Testando config do Nginx..."
nginx -t

echo "==> Iniciando/recarregando Nginx..."
systemctl enable nginx
systemctl reload nginx || systemctl start nginx

echo ""
echo "==> Obtendo certificados SSL (Let's Encrypt)..."
echo "    Certifique-se que DNS api.zavycrm.com e chat.zavycrm.com apontam para esta VPS."
echo ""
certbot --nginx \
  -d api.zavycrm.com \
  -d chat.zavycrm.com \
  --non-interactive \
  --agree-tos \
  --email admin@zavycrm.com \
  --redirect

echo ""
echo "==> Testando config final com SSL..."
nginx -t && systemctl reload nginx

echo ""
echo "==> Configurando renovação automática..."
systemctl enable certbot.timer 2>/dev/null || true
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && systemctl reload nginx") \
  | sort -u | crontab -

echo ""
echo "✅ Nginx + SSL configurados!"
echo "   https://api.zavycrm.com/up   → deve retornar 200"
echo "   https://chat.zavycrm.com     → Chatwoot"
