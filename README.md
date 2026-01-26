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



