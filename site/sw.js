importScripts('./db.js');
const SHELL = 'craft-shell-v1';
const PREFIX = 'craft-app-v1-';
const BASE = new URL(self.registration.scope);
const shell = ['./', 'index.html', 'app.js', 'db.js', 'manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png'];
self.addEventListener('install', event => {
  event.waitUntil(caches.open(SHELL).then(cache => cache.addAll(shell.map(path => new URL(path, BASE).href))).then(() => self.skipWaiting()));
});
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (event.request.method !== 'GET' || url.origin !== BASE.origin || !url.pathname.startsWith(BASE.pathname)) return;
  const relative = url.pathname.slice(BASE.pathname.length);
  if (!relative || relative === 'index.html' || shell.includes(relative)) {
    event.respondWith((async () => {
      const cache = await caches.open(SHELL);
      try {
        const response = await fetch(event.request);
        if (response.ok) await cache.put(new URL(relative || './', BASE).href, response.clone());
        return response;
      } catch (error) {
        return (await cache.match(new URL(relative || './', BASE).href)) || Response.error();
      }
    })());
    return;
  }
  const app = relative.split('/')[0];
  if (!relative.includes('/')) return;
  event.respondWith((async () => {
    try {
      const entry = await dbRequest('apps', 'readonly', store => store.get(app));
      if (entry && entry.cache.startsWith(PREFIX)) {
        const cache = await caches.open(entry.cache);
        // Query parameters select app modes; the underlying static file is unchanged.
        const key = new URL(url.href);
        key.search = ''; key.hash = '';
        if (key.pathname.endsWith('/')) key.pathname += 'index.html';
        const cached = await cache.match(key.href);
        if (cached) return cached;
      }
    } catch (error) { console.error('Offline cache lookup failed', error); }
    return fetch(event.request);
  })());
});

self.addEventListener('message', event => {
  const { type, app, requestId } = event.data || {};
  if (!['DOWNLOAD_APP', 'REMOVE_APP'].includes(type) || !/^[a-z0-9-]+$/.test(app || '')) return;
  const notify = (status, detail = {}) => event.source?.postMessage({ requestId, app, status, ...detail });
  event.waitUntil((async () => {
    let staging;
    try {
      if (type === 'REMOVE_APP') {
        const previous = await dbRequest('apps', 'readonly', store => store.get(app));
        await dbRequest('apps', 'readwrite', store => store.delete(app));
        if (previous && previous.cache.startsWith(PREFIX)) await caches.delete(previous.cache);
        notify('removed');
        return;
      }
      const manifestResponse = await fetch(new URL('offline-apps.json', BASE), { cache: 'no-store' });
      if (!manifestResponse.ok) throw new Error('Could not load the app file list.');
      const manifest = await manifestResponse.json();
      const entry = manifest[app];
      if (!entry || !Array.isArray(entry.files) || !entry.files.length) throw new Error('App not found in the offline file list.');
      staging = `${PREFIX}${app}-${Date.now()}-${Math.random().toString(36).slice(2)}`;
      const cache = await caches.open(staging);
      let count = 0;
      for (const path of entry.files) {
        const url = new URL(path, BASE);
        if (url.origin !== BASE.origin || !url.pathname.startsWith(`${BASE.pathname}${app}/`)) throw new Error('Invalid app file path.');
        const response = await fetch(url.href, { cache: 'no-store' });
        if (!response.ok) throw new Error(`Download failed (${response.status}): ${path}`);
        await cache.put(url.href, response);
        notify('progress', { count: ++count, total: entry.files.length });
      }
      const previous = await dbRequest('apps', 'readonly', store => store.get(app));
      await dbRequest('apps', 'readwrite', store => store.put({ id: app, cache: staging, version: entry.version, savedAt: Date.now() }));
      staging = null; // The new cache is now active. Keep the old one until this point.
      if (previous && previous.cache.startsWith(PREFIX)) await caches.delete(previous.cache);
      notify('ready');
    } catch (error) {
      if (staging) await caches.delete(staging);
      notify('error', { message: error.message || 'Offline storage failed.' });
    }
  })());
});
