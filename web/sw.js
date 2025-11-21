const CACHE_NAME = 'seguruni-v1';
const OFFLINE_URL = '/offline.html';

// Recursos esenciales para precachear
const PRECACHE_URLS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/favicon.png',
  '/offline.html'
];

// Lista de archivos críticos de Flutter que NO deben bloquearse
const FLUTTER_CRITICAL_FILES = [
  'flutter_bootstrap.js',
  'flutter.js',
  'main.dart.js',
  'flutter_service_worker.js'
];

self.addEventListener('install', (event) => {
  console.log('✅ [SW] Instalando...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('📦 [SW] Cacheando recursos...');
        return cache.addAll(PRECACHE_URLS);
      })
      .then(() => self.skipWaiting())
      .catch((error) => {
        console.error('❌ [SW] Error al cachear:', error);
      })
  );
});

self.addEventListener('activate', (event) => {
  console.log('✅ [SW] Activando...');
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('🗑️ [SW] Limpiando cache viejo:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  // Solo manejar GET requests
  if (event.request.method !== 'GET') return;
  
  const url = new URL(event.request.url);
  
  // NO interceptar archivos críticos de Flutter - dejar que pasen directo
  const isCriticalFlutterFile = FLUTTER_CRITICAL_FILES.some(file => 
    url.pathname.includes(file)
  );
  
  if (isCriticalFlutterFile) {
    console.log('⚡ [SW] Permitiendo paso directo a:', url.pathname);
    return; // Dejar que el navegador maneje estos archivos normalmente
  }
  
  // Ignorar Firebase y APIs externas
  if (url.hostname.includes('firebase') ||
      url.hostname.includes('firestore') ||
      url.hostname.includes('googleapis') ||
      url.hostname.includes('gstatic')) {
    return;
  }

  // Estrategia: Network First con Cache Fallback
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Si la respuesta es exitosa, cachearla
        if (response && response.status === 200 && response.type === 'basic') {
          const responseClone = response.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(event.request, responseClone);
          });
        }
        return response;
      })
      .catch(() => {
        // Si falla la red, buscar en cache
        return caches.match(event.request)
          .then((cachedResponse) => {
            if (cachedResponse) {
              console.log('📂 [SW] Sirviendo desde cache:', url.pathname);
              return cachedResponse;
            }
            
            // Si es navegación y no hay cache, mostrar página offline
            if (event.request.mode === 'navigate') {
              console.log('📵 [SW] Mostrando página offline');
              return caches.match(OFFLINE_URL);
            }
            
            // Para otros recursos, devolver respuesta offline
            return new Response('Offline', { 
              status: 503,
              statusText: 'Service Unavailable'
            });
          });
      })
  );
});