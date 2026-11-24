// يعمل البرنامج بدون إنترنت: الشبكة أولًا (بدون ذاكرة المتصفح المؤقتة) ثم النسخة المخزنة
const CACHE='ali-amlak-claude-v14';
const CORE=['./','./index.html','./manifest.json','./icon.svg'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(CORE.map(u=>new Request(u,{cache:'reload'})))).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{
  const u=new URL(e.request.url);
  if(e.request.method!=='GET'||u.hostname.endsWith('supabase.co'))return;
  const own=u.origin===location.origin;
  const req=own?new Request(e.request,{cache:'no-store'}):e.request;
  e.respondWith(fetch(req).then(r=>{if(r.ok&&(own||u.hostname.includes('fonts.g')||u.hostname.includes('jsdelivr')))  {const cp=r.clone();caches.open(CACHE).then(c=>c.put(e.request,cp))}return r}).catch(()=>caches.match(e.request,{ignoreSearch:true}).then(m=>m||caches.match('./index.html'))));
});
