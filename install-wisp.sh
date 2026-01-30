#!/bin/bash

# SPLASHP + wisp one-liner installer 
# this version also installs a wisp server at /wisp/
# Usage:
# curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install-wisp.sh | bash -s -- [--port 8080]
#   --port {port}   Changes the port it runs at

set -e

cat <<'BANNER'

 ______     ______   __         ______     ______     __  __     ______  
/\  ___\   /\  == \ /\ \       /\  __ \   /\  ___\   /\ \_\ \   /\  == \ 
\ \___  \  \ \  _-/ \ \ \____  \ \  __ \  \ \___  \  \ \  __ \  \ \  _-/ 
 \/\_____\  \ \_\    \ \_____\  \ \_\ \_\  \/\_____\  \ \_\ \_\  \ \_\   
  \/_____/   \/_/     \/_____/   \/_/\/_/   \/_____/   \/_/\/_/   \/_/   by RHW
                                                                           v0.4.4
 Now with WISP integration!
 Secure Proxy for Live Audiovisual SHell Portable

BANNER

PORT=8080
ASK_PORT=$((30000 + RANDOM % 20000))


while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      PORT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
 done

echo "Port: $PORT"
echo "BYOD Ask port: $ASK_PORT"
SERVER_IP=$(hostname -I | awk '{print $1}')

# -----------------------
# System dependencies
# -----------------------
echo "Ensuring sudo is installed..."
if ! command -v sudo >/dev/null; then
  apt-get update
  apt-get install -y sudo
fi

APP_DIR="$HOME/splashp"
if [ -d "$APP_DIR" ]; then
    echo "Cleaning up previous SPLASHP installation in $APP_DIR..."
    rm -rf "$APP_DIR/main.js" "$APP_DIR/node_modules"
fi
mkdir -p "$APP_DIR"

# -----------------------
# Cleanup Caddy config
# -----------------------
CADDYFILE="/etc/caddy/Caddyfile"
if [ -f "$CADDYFILE" ]; then
    echo "Cleaning up previous SPLASHP Caddy configuration..."
    [ ! -f "${CADDYFILE}.bak" ] && sudo cp "$CADDYFILE" "${CADDYFILE}.bak"
    sudo sed -i '/reverse_proxy 127.0.0.1:[0-9]\+/d' "$CADDYFILE"
fi

# -----------------------
# Cleanup Caddy GPG and source list
# -----------------------
CADDY_KEY="/usr/share/keyrings/caddy-stable-archive-keyring.gpg"
CADDY_LIST="/etc/apt/sources.list.d/caddy-stable.list"
[ -f "$CADDY_KEY" ] && sudo rm -f "$CADDY_KEY"
[ -f "$CADDY_LIST" ] && sudo rm -f "$CADDY_LIST"

sudo apt-get update
sudo apt-get install -y curl openssl build-essential

# -----------------------
# Install Node.js LTS
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
# Setup Node app
# -----------------------
cd "$APP_DIR"
npm init -y >/dev/null

npm install http-proxy @mercuryworkshop/wisp-js

cat > main.js <<EOF
const http = require("http");
const httpProxy = require("http-proxy");
const { server: wisp, logging } = require("@mercuryworkshop/wisp-js/server");

const PORT = $PORT;
const ASK_PORT = $ASK_PORT;

logging.set_level(logging.DEBUG);
wisp.options.port_whitelist = [80, 443, [5000, 6000]];

const proxy = httpProxy.createProxyServer({
  target: "https://splash.best",
  changeOrigin: true,
  secure: true,
});

proxy.on("error", (err, req, res) => {
  console.error("Proxy error:", err);
  if (res.writeHead) {
    res.writeHead(502, { "Content-Type": "text/plain" });
    res.end("Bad gateway");
  }
});

const server = http.createServer((req, res) => {
  if (req.url.startsWith("/wisp")) {
    wisp.routeRequest(req, res);
  } else {
    proxy.web(req, res);
  }
});

server.on("upgrade", (req, socket, head) => {
  if (req.url.startsWith("/wisp")) {
    wisp.routeRequest(req, socket, head);
  } else {
    proxy.ws(req, socket, head);
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(\`Node proxy running on port \${PORT}\`);
  console.log(\`- WISP available at /wisp\`);
});

http.createServer((req, res) => {
  // Always allow (BYOD-friendly)
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("ok");
}).listen(ASK_PORT, "127.0.0.1", () => {
  console.log(\`Caddy ask endpoint listening on 127.0.0.1:\${ASK_PORT}\`);
});
EOF

pm2 delete splashp-proxy >/dev/null 2>&1 || true
pm2 start main.js --name splashp-proxy
pm2 startup systemd -u "$USER" --hp "$HOME"
pm2 save

# -----------------------
# Caddy config
# -----------------------
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
{
    on_demand_tls {
        ask http://127.0.0.1:$ASK_PORT/ask
    }
}

:443 {
    tls {
        on_demand
    }
    reverse_proxy 127.0.0.1:$PORT
}

:80 {
    redir https://{host}{uri} permanent
}
EOF



sudo systemctl reload caddy

# -----------------------
# Done
# -----------------------
echo
echo "========================================="
echo "SPLASHP + wisp is live."
echo "POINT DOMAIN TO: $SERVER_IP"
echo "HTTPS handled automatically by Caddy." 
echo "Internal port: $PORT"
echo "pm2 process: splashp-proxy"
echo "WISP available at /wisp"
echo "========================================="
