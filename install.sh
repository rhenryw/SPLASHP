#!/bin/bash

# SPLASHP one-liner installer 
# Usage:
# curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash [--tiny] [--port 8080]
#   --tiny          Use main-tiny.js (pure Node, no http-proxy)
#   --port {port}   Changes the port it runs at

set -e

cat <<'BANNER'

 ______     ______   __         ______     ______     __  __     ______  
/\  ___\   /\  == \ /\ \       /\  __ \   /\  ___\   /\ \_\ \   /\  == \ 
\ \___  \  \ \  _-/ \ \ \____  \ \  __ \  \ \___  \  \ \  __ \  \ \  _-/ 
 \/\_____\  \ \_\    \ \_____\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\   
  \/_____/   \/_/     \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/   by RHW
                                                                           v0.3.3
 Now with BYOD support!
 Secure Proxy for Live Audiovisual SHell Portable

BANNER

USE_TINY=false
PORT=8080

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tiny)
      USE_TINY=true
      shift
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

echo "Port:   $PORT"
echo "Mode:   $([[ $USE_TINY == true ]] && echo tiny || echo http-proxy)"
SERVER_IP=$(hostname -I | awk '{print $1}')


# -----------------------
# System dependencies
# -----------------------
echo "Ensuring sudo is installed..."
if ! command -v sudo >/dev/null; then
  apt-get update
  apt-get install -y sudo
fi

sudo apt-get update
sudo apt-get install -y curl openssl build-essential

# -----------------------
# Install Node.js (LTS)
# -----------------------
echo "Installing Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs

# -----------------------
# Install pm2
# -----------------------
echo "Installing pm2..."
sudo npm install -g pm2

# -----------------------
# Install Caddy
# -----------------------
echo "Installing Caddy..."
sudo apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt-get update
sudo apt-get install -y caddy

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
  console.log(`SPLASHP running on http://localhost:${PORT} -> https://splash.best`);
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
  console.log(`SPLASHP running on http://localhost:${PORT} -> https://splash.best`);
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
# Caddy config (ANY domain)
# -----------------------
echo "Configuring Caddy..."

sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
:80, :443 {
    reverse_proxy 127.0.0.1:$PORT
}
EOF

sudo systemctl reload caddy

# -----------------------
# Done
# -----------------------
echo
echo "========================================="
echo "SPLASHP is live."
echo "POINT DOMAIN TO: $SERVER_IP"
echo "HTTPS will be automatic."
echo "Internal port: $PORT"
echo "pm2 process: splashp-proxy"
echo "========================================="
