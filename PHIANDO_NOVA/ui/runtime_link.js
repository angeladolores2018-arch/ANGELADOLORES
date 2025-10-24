import http from "http";
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end("<h1>🌸 PhiANDO_NOVA Active</h1>");
}).listen(3000, ()=>console.log("💫 UI ready at http://localhost:3000"));
