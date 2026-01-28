#!/bin/bash

# SPLASHP one-liner installer
# Usage:
# curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash -s yourdomain.tld [-c] [--tiny] [--port 8080]
#   -c              Enable Certbot SSL
#   --tiny          Use main-tiny.js (pure Node, no http-proxy)
#   --port {port}   Changes the port it runs at

set -e

cat <<'BANNER'

 ______     ______   __         ______     ______     __  __     ______  
/\  ___\   /\  == \ /\ \       /\  __ \   /\  ___\   /\ \_\ \   /\  == \ 
\ \___  \  \ \  _-/ \ \ \____  \ \  __ \  \ \___  \  \ \  __ \  \ \  _-/ 
 \/\_____\  \ \_\    \ \_____\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\   
  \/_____/   \/_/     \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/   by RHW
                                                                           v0.2.0

 Secure Proxy for Live Audiovisual SHell Portable

BANNER

SSL_ENABLED=false
USE_TINY=false
DOMAIN=""
PORT=8080


while [[ $# -gt 0 ]]; do
  case "$1" in
    -c)
      SSL_ENABLED=true
      shift
      ;;
    --tiny)
      USE_TINY=true
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      if [[ -z "$DOMAIN" ]]; then
        DOMAIN="$1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$DOMAIN" ]]; then
  echo "Error: Domain not provided."
  exit 1
fi

echo "Domain: $DOMAIN"
echo "Port:   $PORT"
echo "Mode:   $([[ $USE_TINY == true ]] && echo tiny || echo http-proxy)"

# -----------------------
# System dependencies
# -----------------------
apt-get update
apt-get install -y sudo
sudo apt update && sudo apt upgrade -y
sudo apt update
sudo apt-get update
sudo apt-get install -y curl nginx openssl build-essential

echo "Installing Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "Installing pm2..."
sudo npm install -g pm2

# -----------------------
# App directory
# -----------------------
APP_DIR="$HOME/splashp"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

npm init -y >/dev/null

# -----------------------
# Write JS proxy
# -----------------------
if [[ "$USE_TINY" == true ]]; then
  echo "Writing main-tiny.js..."

  cat > main-tiny.js <<EOF
const http = require("http");
const https = require("https");

const TARGET_HOST = "splash.best";
const PORT = $PORT;

http.createServer((req, res) => {
  const proxyReq = https.request({
    hostname: TARGET_HOST,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: TARGET_HOST,
    },
  }, proxyRes => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  req.pipe(proxyReq);

  proxyReq.on("error", err => {
    console.error(err);
    res.writeHead(502);
    res.end("Bad gateway");
  });
}).listen(PORT, () => {
  console.log(\`SPLASHP running on http://localhost:\${PORT} -> https://splash.best\`);
});
EOF

  APP_FILE="main-tiny.js"

else
  echo "Installing http-proxy..."
  npm install http-proxy

  echo "Writing main.js..."

  cat > main.js <<EOF
const http = require("http");
const httpProxy = require("http-proxy");

const PORT = $PORT;

const proxy = httpProxy.createProxyServer({
  target: "https://splash.best",
  changeOrigin: true,
  secure: true,
});

proxy.on("error", (err, req, res) => {
  console.error("Proxy error:", err);
  res.writeHead(502, { "Content-Type": "text/plain" });
  res.end("Bad gateway");
});

http.createServer((req, res) => {
  proxy.web(req, res);
}).listen(PORT, () => {
  console.log(\`SPLASHP running on http://localhost:\${PORT} -> https://splash.best\`);
});
EOF

  APP_FILE="main.js"
fi

# -----------------------
# pm2 stuff that might not work because I don't usually use pm2
# -----------------------
pm2 delete splashp-proxy >/dev/null 2>&1 || true
pm2 start "$APP_FILE" --name splashp-proxy
pm2 startup systemd -u "$USER" --hp "$HOME"
pm2 save

# -----------------------
# nginx rahh!!!
# -----------------------
echo "Configuring NGINX..."

sudo tee /etc/nginx/sites-available/splashp.conf > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
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
sudo systemctl restart nginx

# -----------------------
# SSL *yawn*
# -----------------------
if [[ "$SSL_ENABLED" == true ]]; then
  sudo apt-get install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN --redirect
fi

echo
echo "========================================="
echo "SPLASHP is live at:"
echo "  $([[ $SSL_ENABLED == true ]] && echo https || echo http)://$DOMAIN"
echo "Internal port: $PORT"
echo "pm2 process: splashp-proxy"
echo "========================================="
