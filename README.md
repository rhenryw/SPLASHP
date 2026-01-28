# SPLASHP
Secure Proxy for Live Audiovisual SHell Portable - a CLI themed web proxy (reverse proxied for easy deployment)


See [main repo](https://github.com/rhenryw/SPLASH)


This is a node.js proxy for super quick and easy deployment of SPLASH, if you want to use a VPS instead of a service like Netlify.

`main.js` vs `main-tiny.js`
---

`main.js` uses `http-proxy` library, and therefore it must be installed with `npm i http-proxy`, whereas `main-tiny.js` is PURE node. However `main.js` is more powerful and generally reccomended over `main-tiny.js`, and `main-tiny.js` is just included for legacy system compatibility.

---
HOW TO INSTALL (one-click easy way)
---

> [!NOTE]  
> This one liner was created with __AI Assistance__. It was put into ChatGPT with the __Human Created__ [deployWisp](https://github.com/rhenryw/deployWisp/blob/main/install.sh) script, and the __Human Created__ instructions below and told to make a similar script with the instructions below, than human-tested. This is to save time.


Start with a clean Ubuntu/Debian Sever

Point your domain/subdomain using an `A` record to your VPS (get IP using `hostname -i` if you don't know the IP)
```bash
curl -fsSL https://raw.githubusercontent.com/rhenryw/SPLASHP/main/install.sh | bash -s yourdomain.tld 
```
Replace `yourdomain.tld` with your domain/subdomain you want SPLASH to deploy on.

- Append `-c` to enable Certbot SSL certificates (if you don't proxy through cloudflare or if it doesn't provide SSL for you. If you are using Cloudflare make sure the `A` record is set to `proxied` (shows a little orange cloud with an arrow through it) and your SSL/TLS setting is set to "Flexible")

- Append `--tiny` to use main-tiny.js (pure Node, no http-proxy), which is good for older servers.

- Append `--port {port}` to change the port that it will run at.

If you don't want NGINX to automatically install, or if you aren't using debain, follow the detailed non-one-liner instructions below.

---
HOW TO INSTALL (non one-liner):
---

> [!IMPORTANT]  
> Due to GitHub codespaces being stupid there *may* not be required node files so you might also have to run `npm init -y` in the `SPLASHP` directory before installing and running anything (right after cloning the repo). I will include it in the installation for now but it may become obsolete in the future.


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
https://github.com/rhenryw/SPLASHP.git
```
(or your preffered method of Git installation)

CD into the directory
```bash
cd SPLASHP
npm init -y
```

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



