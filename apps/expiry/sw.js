const CACHE='expiry-v5-511';
const ASSETS=['./manifest.webmanifest'];
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)).then(()=>self.skipWaiting())));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{const u=new URL(e.request.url);if(u.hostname.includes('supabase.co')||e.request.method!=='GET')return;if(e.request.mode==='navigate'||u.pathname.endsWith('/index.html')||u.pathname.endsWith('/expiry/')){e.respondWith(fetch(e.request,{cache:'no-store'}).catch(()=>caches.match('./index.html')));return}e.respondWith(fetch(e.request,{cache:'no-store'}).catch(()=>caches.match(e.request)))});
