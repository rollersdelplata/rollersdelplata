# Límites y Cuotas de los Tiers Gratuitos (Referencia Rápida)

Ten en cuenta estos límites al diseñar consultas, almacenamiento de imágenes y despliegues.

## 1. Supabase Free Tier ($0/mes — Sin tarjeta de crédito)

| Recurso | Límite Gratuito | Estrategia de Optimización |
| :--- | :--- | :--- |
| **Proyectos activos** | Hasta 2 proyectos gratuitos por organización | Usar esquemas o prefijos de tablas si se quieren alojar micro-proyectos relacionados en la misma instancia. |
| **Base de datos PostgreSQL** | **500 MB** de espacio | Guardar solo texto, metadatos y URLs en la DB. **Nunca** guardar archivos ni imágenes en base64/`bytea` dentro de tablas. |
| **Storage (Archivos / Imágenes)** | **1 GB** de almacenamiento | Comprimir toda imagen en el navegador a **WebP** (~80-150 KB por imagen = ~7,000 a 10,000 imágenes en 1 GB). |
| **Egress (Transferencia saliente)** | **5 GB / mes** (Cached + Uncached) | Subir imágenes con `cacheControl: '31536000'` (1 año) y pedir solo las columnas necesarias (`select('id, title')` en vez de `select('*')`) con paginación (`.range(0, 19)`). |
| **Tamaño máx. por archivo en Storage** | **50 MB** | Restringir en el bucket y en el frontend a **2 MB - 5 MB** máximo por imagen. |
| **Usuarios Autenticados (Auth)** | **50,000 MAU** (Usuarios activos mensuales) | Suficiente para la gran mayoría de aplicaciones en producción inicial. |
| **Inactividad** | Se pausa tras **7 días sin actividad** | Configurar un cron gratuito en **GitHub Actions** que haga una consulta ligera cada 5 días. |

---

## 2. Cloudflare Free Tier ($0/mes)

| Servicio | Límite Gratuito | Estrategia de Optimización |
| :--- | :--- | :--- |
| **Cloudflare Pages (Sitios estáticos)** | **Ancho de banda ILIMITADO** y peticiones estáticas ilimitadas; 500 builds/mes | Ideal para alojar todo el frontend, assets del diseño, fuentes e íconos estáticos en el repo. |
| **Cloudflare Workers / Pages Functions** | **100,000 peticiones / día** (10 ms CPU por invocación) | No pasar activos estáticos por el Worker; usar funciones solo para endpoints de API reales. |
| **Cloudflare R2 (Object Storage)** | **10 GB / mes** de almacenamiento, **0 costo de Egress** (transferencia saliente gratis), 1M escrituras (Clase A) y 10M lecturas (Clase B) al mes | Si la web supera 1 GB de imágenes de usuarios o tiene mucho tráfico de visualización de fotos, migrar el bucket de imágenes a R2 servido tras un dominio/subdominio en Cloudflare. |
| **Cloudflare D1 / KV (Opcional)** | D1: 5 GB total, 5M lecturas/día. KV: 100k lecturas/día | Útil para caché en el borde, aunque Supabase PostgreSQL es más potente para relaciones SQL y Auth con RLS. |

---

## 3. GitHub Free Tier ($0/mes)

| Recurso | Límite Gratuito | Uso en nuestro Stack |
| :--- | :--- | :--- |
| **Repositorios públicos y privados** | Ilimitados | Control de versiones conectado directamente a Cloudflare Pages para despliegue automático en cada `git push` (Preview por rama/PR y Production en `main`). |
| **GitHub Actions** | **2,000 minutos / mes** en repos privados (ilimitado en repos públicos) | Ejecutar tests/linters y correr el cron de *Keep-Alive* para mantener despierta la base de datos de Supabase. |
