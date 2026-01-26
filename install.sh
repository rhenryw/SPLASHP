#!/bin/bash

# SPLASHP one-liner for SPLASH by RHW
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash -s yourdomain.tld [-c] [--tiny]
#   -c      Enable Certbot SSL
#   --tiny  Use main-tiny.js (pure Node, no http-proxy)

set -e

cat <<'BANNER'

 ______     ______   __         ______     ______     __  __     ______  
/\  ___\   /\  == \ /\ \       /\  __ \   /\  ___\   /\ \_\ \   /\  == \ 
\ \___  \  \ \  _-/ \ \ \____  \ \  __ \  \ \___  \  \ \  __ \  \ \  _-/ 
 \/\_____\  \ \_\    \ \_____\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\   
  \/_____/   \/_/     \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/   by RHW
                                                                           v0.1.0

 Secure Proxy for Live Audiovisual SHell Portable

BANNER

SSL_ENABLED=false
USE_TINY=false
DOMAIN=""

for arg in "$@"; do
  case $arg in
    -c)
      SSL_ENABLED=true
      ;;
    --tiny)
      USE_TINY=true
      ;;
    *)
      if [[ -z "$DOMAIN" ]]; then
        DOMAIN=$arg
      fi
      ;;
  esac
done

if [ -z "$DOMAIN" ]; then
  echo "Error: Domain not provided."
  echo "Usage: curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash -s yourdomain.tld [-c] [--tiny]"
  exit 1
fi

echo "Ensuring sudo is installed..."
if ! command -v sudo >/dev/null; then
  apt-get update
  apt-get install -y sudo
fi

echo "Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y curl git nginx openssl build-essential

echo "Installing Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installing pm2..."
sudo npm install -g pm2

echo "Updating and clearing old SPLASHP repo..."
rm -rf SPLASHP

echo "Cloning SPLASHP repository..."
REPO_URL="https://github.com/rhenryw/SPLASHP.git"
TARGET_DIR="SPLASHP"
git clone "$REPO_URL"
cd "$TARGET_DIR"

echo "Initializing npm (if needed)..."
[ ! -f package.json ] && npm init -y

if [ "$USE_TINY" = false ]; then
  echo "Installing http-proxy (main.js mode)..."
  npm install http-proxy
fi

APP_FILE="main.js"
if [ "$USE_TINY" = true ]; then
  APP_FILE="main-tiny.js"
fi

echo "Starting SPLASHP with pm2 ($APP_FILE)..."
pm2 delete splashp-proxy >/dev/null 2>&1 || true
pm2 start "$APP_FILE" --name splashp-proxy

pm2 startup systemd -u "$USER" --hp "$HOME"
pm2 save

echo "Writing NGINX configuration..."
sudo tee /etc/nginx/sites-available/splashp.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/splashp.conf /etc/nginx/sites-enabled/splashp.conf
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

if [ "$SSL_ENABLED" = true ]; then
  echo "Installing Certbot..."
  sudo apt-get install -y certbot python3-certbot-nginx

  echo "Obtaining SSL certificate for $DOMAIN..."
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN --redirect

  sudo systemctl enable certbot.timer
  sudo systemctl start certbot.timer
fi

echo
echo "========================================="
if [ "$SSL_ENABLED" = true ]; then
  echo "SPLASH (portable deployment) is live at: https://$DOMAIN"
else
  echo "SPLASH (portable deployment) is live at: http://$DOMAIN"
  echo "(Re-run with -c to enable SSL)"
fi
echo "pm2 process name: splashp-proxy"
echo "========================================="
