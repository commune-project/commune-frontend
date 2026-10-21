import fs from 'node:fs';
import http from 'node:http';
import https from 'node:https';
import path from 'node:path';

const root = path.resolve('dist');
const types = {
  '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8', '.png': 'image/png', '.svg': 'image/svg+xml'
};

function proxy(request, response) {
  const upstream = http.request({
    hostname: '127.0.0.1', port: 18080, method: request.method, path: request.url,
    headers: { ...request.headers, host: 'localhost:8443' }
  }, result => {
    response.writeHead(result.statusCode || 502, result.headers);
    result.pipe(response);
  });
  upstream.on('error', () => {
    response.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
    response.end('{"error":"backend unavailable"}');
  });
  request.pipe(upstream);
}

https.createServer({
  key: fs.readFileSync('/tmp/commune-frontend-key.pem'),
  cert: fs.readFileSync('/tmp/commune-frontend-cert.pem')
}, (request, response) => {
  if (request.url.startsWith('/api/')) { proxy(request, response); return; }
  let pathname;
  try { pathname = decodeURIComponent(new URL(request.url, 'https://localhost').pathname); }
  catch { response.writeHead(400); response.end('bad request'); return; }
  let file = path.join(root, pathname);
  if (!file.startsWith(root)) { response.writeHead(403); response.end('forbidden'); return; }
  if (!fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    if (path.extname(pathname)) { response.writeHead(404); response.end('not found'); return; }
    file = path.join(root, 'index.html');
  }
  response.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
  if (pathname.startsWith('/assets/')) response.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
  fs.createReadStream(file).pipe(response);
}).listen(8443, '127.0.0.1', () => console.log('https://localhost:8443'));
