#!/usr/bin/env bash
set -euo pipefail

: "${PUBLIC_DIR:?PUBLIC_DIR not set}"

cat > "$PUBLIC_DIR/manifest.json" << 'JSON'
{
  "name": "Snort",
  "short_name": "Snort",
  "start_url": "/",
  "display": "standalone"
}
JSON

cat > "$PUBLIC_DIR/sw.js" << 'JS'
self.addEventListener('install', event => {
  event.waitUntil(caches.open('snort-shell').then(cache => cache.addAll(['/'])));
});
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(resp => resp || fetch(event.request))
  );
});
JS
