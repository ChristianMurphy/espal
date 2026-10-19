// The Node.js reference: node:http as its docs show, one process per invocation.
const http = require("node:http");

const port = Number(process.argv[2] ?? 8080);

http
  .createServer((req, res) => {
    if (req.url === "/plaintext") {
      res.writeHead(200, { "Content-Type": "text/plain", Server: "Node" });
      res.end("Hello, World!");
    } else if (req.url === "/json") {
      res.writeHead(200, { "Content-Type": "application/json", Server: "Node" });
      res.end(JSON.stringify({ message: "Hello, World!" }));
    } else {
      res.writeHead(404);
      res.end();
    }
  })
  .listen(port, "127.0.0.1");
