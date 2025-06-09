import http from 'http';
import https from 'https';
import { readFile } from 'fs/promises';
import { URL } from 'url';

const apiKey = process.env.OPENFIGI_API_KEY;

async function apiCall(path, data) {
  const options = {
    hostname: 'api.openfigi.com',
    path: path,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(apiKey && { 'X-OPENFIGI-APIKEY': apiKey }),
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => (responseData += chunk));
      res.on('end', () => {
        try {
          resolve(JSON.parse(responseData));
        } catch (err) {
          reject(err);
        }
      });
    });
    req.on('error', reject);
    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

const server = http.createServer(async (req, res) => {
  const parsedUrl = new URL(req.url, 'http://localhost');
  if (req.method === 'GET' && parsedUrl.pathname === '/') {
    const html = await readFile(new URL('./public/index.html', import.meta.url));
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(html);
    return;
  }

  if (req.method === 'GET' && parsedUrl.pathname.startsWith('/static/')) {
    const path = parsedUrl.pathname.replace('/static/', '');
    try {
      const file = await readFile(new URL('./public/' + path, import.meta.url));
      const headers = path.endsWith('.js')
        ? { 'Content-Type': 'application/javascript' }
        : path.endsWith('.css')
        ? { 'Content-Type': 'text/css' }
        : { 'Content-Type': 'application/octet-stream' };
      res.writeHead(200, headers);
      res.end(file);
    } catch {
      res.writeHead(404);
      res.end();
    }
    return;
  }

  if (req.method === 'POST' && parsedUrl.pathname === '/search') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      try {
        const data = JSON.parse(body || '{}');
        const result = await apiCall('/v3/search', data);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (err) {
        res.writeHead(500);
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  if (req.method === 'POST' && parsedUrl.pathname === '/mapping') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      try {
        const { requests } = JSON.parse(body || '{}');
        const result = await apiCall('/v3/mapping', requests);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (err) {
        res.writeHead(500);
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  res.writeHead(404);
  res.end();
});

server.listen(3000, () => {
  console.log('Server running at http://localhost:3000/');
});
