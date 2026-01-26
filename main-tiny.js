const http = require("http");
const https = require("https");

const TARGET_HOST = "splash.best";

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
}).listen(8080, () => {
  console.log("SPLASH proxy deployment running on http://localhost:8080 -> https://splash.best");
});
