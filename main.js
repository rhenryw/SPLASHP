const http = require("http");
const httpProxy = require("http-proxy");

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
}).listen(8080, () => {
  console.log("SPLASH proxy deployment running on http://localhost:8080 -> https://splash.best");
});
