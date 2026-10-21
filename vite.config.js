import { defineConfig } from 'vite';
import { existsSync } from 'node:fs';
import path from 'node:path';

function rejectMissingCatalogs(baseDirectory) {
  return (request, response, next) => {
    let pathname;
    try { pathname = decodeURIComponent(new URL(request.url, 'http://local').pathname); }
    catch { next(); return; }
    if (!pathname.startsWith('/assets/i18n/')) { next(); return; }
    const file = path.join(baseDirectory, pathname.slice(1));
    if (existsSync(file)) { next(); return; }
    response.statusCode = 404;
    response.setHeader('Content-Type', 'text/plain; charset=utf-8');
    response.setHeader('Cache-Control', 'no-store');
    response.end('translation asset not found');
  };
}

function rejectUnproxiedApi(request, response, next) {
  if (!request.url?.startsWith('/api/')) { next(); return; }
  response.statusCode = 503;
  response.setHeader('Content-Type', 'application/json; charset=utf-8');
  response.end('{"error":"backend proxy not configured"}');
}

function translationAssetsDoNotUseSpaFallback() {
  return {
    name: 'translation-assets-do-not-use-spa-fallback',
    configureServer(server) {
      server.middlewares.use(rejectMissingCatalogs(server.config.publicDir));
      if (!process.env.COMMUNE_BACKEND) {
        server.middlewares.use(rejectUnproxiedApi);
      }
    },
    configurePreviewServer(server) {
      server.middlewares.use(rejectMissingCatalogs(path.resolve(server.config.root, server.config.build.outDir)));
      server.middlewares.use(rejectUnproxiedApi);
    }
  };
}

export default defineConfig({
  plugins: [translationAssetsDoNotUseSpaFallback()],
  server: { proxy: process.env.COMMUNE_BACKEND ? {
    '/api': { target: process.env.COMMUNE_BACKEND, changeOrigin: true, secure: true }
  } : undefined },
  build: { target: 'es2022' }
});
