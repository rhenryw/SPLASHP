# SPLASHP
Secure Proxy for Live Audiovisual SHell (SPLASH) Portable 
A CLI-themed reverse proxy for easy VPS deployment

### Now with BYOD Support

See [main repo](https://github.com/rhenryw/SPLASH)

## Who is this for?

- You want to self-host SPLASH on a VPS
- You don’t want to deal with manual NGINX + SSL setup
- You don't want to deal with Netlify/Render/Etc.
- You want to set up SPLASH deployment in about 90 seconds

This is a node.js proxy for super quick and easy deployment of SPLASH, if you want to use a VPS instead of a service like Netlify.

`main.js` vs `main-tiny.js`
---

`main.js` uses `http-proxy` library, and therefore it must be installed with `npm i http-proxy`, whereas `main-tiny.js` is PURE node. However `main.js` is more powerful and generally recommended over `main-tiny.js`, and `main-tiny.js` is just included for legacy system compatibility.


---
HOW TO INSTALL PROXY + WISP (one-click easy way)
---

> [!NOTE]  
> This one liner was created with __AI Assistance__. It was put into ChatGPT with the __Human Created__ [deployWisp](https://github.com/rhenryw/deployWisp/blob/main/install.sh) script, and the __Human Created__ instructions below and told to make a similar script with the instructions below, than human-edited and finally human-tested. This is to save time.


Start with a clean Ubuntu/Debian Srever

Point your domain/subdomain using an `A` record to your VPS (get IP using `hostname -i` if you don't know the IP)
```bash
curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install-wisp.sh | bash -s --
```
> [!IMPORTANT]  
> If you are using Cloudflare, make sure the `A` record is set to `proxied` (shows a little orange cloud with an arrow through it) and your SSL/TLS setting is set to "Flexible"

- Append `--port {port}` to change the port that it will run at.

This will create a proxy instance AND a wisp server at `wss://domain.tld/wisp/`

---
HOW TO INSTALL PROXY ONLY (one-click easy way)
---


Start with a clean Ubuntu/Debian Srever

Point your domain/subdomain using an `A` record to your VPS (get IP using `hostname -i` if you don't know the IP)
```bash
curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash -s --
```
> [!IMPORTANT]  
> If you are using Cloudflare, make sure the `A` record is set to `proxied` (shows a little orange cloud with an arrow through it) and your SSL/TLS setting is set to "Flexible"

- Append `--tiny` to use main-tiny.js (pure Node, no http-proxy), which is good for older servers.

- Append `--port {port}` to change the port that it will run at.


---
HOW TO INSTALL (non one-liner):
---

> [!NOTE]  
> This version does not set up Caddy nor SSL Certificates via certbot. This JUST runs the proxy sever and cannot be connected to via a domain without further setup (look up how to, it's not my job to teach you how to set up an NGINX server). Use the one-liner above if you want to set everything up automatically.


Make sure everything is up-to-date and install make sure Git and Node are installed
```bash
apt-get update
apt-get install -y sudo
sudo apt update && sudo apt upgrade -y
sudo apt update
sudo apt install -y git curl
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

```

Verify Installation
```bash
node -v
npm -v
```

Install this repo

```bash
git clone https://github.com/rhenryw/SPLASHP.git
```
(or your preffered method of Git installation)

CD into the directory
```bash
cd SPLASHP
npm init -y
```

Why `npm init -y`? This repo is NOT a full project, rather a skeleton so YOU can deploy your own with your own config. It just has JS and the install shell, that's it.

Start the server (replace `main.js` with `main-tiny.js` if you want PURE node.
```bash
npm i 
npm i http-proxy
sudo npm install -g pm2
pm2 start main.js --name splash-proxy
pm2 startup
pm2 save
```


TO UPDATE
```bash
cd SPLASHP
git pull
npm install
pm2 restart splash-proxy
```



