---
name: image-upload-optimizer
description: >-
  Usa este skill siempre que una web necesite subir, mostrar o eliminar imágenes cuidando los
  planes gratuitos de Supabase Storage (1GB gratis) y Cloudflare R2 (10GB gratis sin egress).
  Implementa compresión en el navegador a WebP antes de subir, validación de archivos, políticas
  RLS de Storage por carpeta de usuario y caché CDN de 1 año.
---

# Image Upload Optimizer (Supabase Storage & Cloudflare R2 Free Tier)

Las imágenes son el recurso que más rápido agota el almacenamiento (1 GB en Supabase Free) y el ancho de banda (5 GB de Egress en Supabase Free) si se suben sin procesar. Este skill estandariza un pipeline de **compresión en el cliente + subida segura** que multiplica por 20x la capacidad del tier gratuito.

---

## 1. Arquitectura Híbrida de Almacenamiento de Imágenes

Elige la estrategia según el volumen del proyecto:

1. **Opción A (Por defecto — 100% sin tarjeta): Compresión Client-Side a WebP + Supabase Storage (1 GB Gratis)**:
   - Ideal para hasta **~8,000 - 10,000 imágenes** comprimidas (~100 KB promedio por imagen en WebP).
   - Se autentica directo con la sesión de Supabase Auth del usuario y políticas RLS sobre `storage.objects`.
2. **Opción B (Alto Volumen — 10 GB Gratis y 0 Egress): Compresión Client-Side a WebP + Cloudflare R2**:
   - Ideal cuando el sitio tendrá decenas de miles de imágenes o muchísimo tráfico público viendo fotos.
   - Se sube a través de un Cloudflare Worker / Pages Function conectado a un bucket R2 (`env.IMAGES_BUCKET`), el cual valida el token JWT de Supabase antes de guardar el archivo.

---

## 2. Pipeline Obligatorio de 4 Pasos al Subir una Imagen

Nunca subas el `File` original del `<input type="file">` directamente. Sigue siempre estos 4 pasos:

### Paso 1: Validación en el Cliente (Antes de procesar)
- Verificar tipo MIME permitido: `image/jpeg`, `image/png`, `image/webp`, `image/avif`.
- Verificar peso bruto de entrada: rechazar archivos mayores a **10 MB** antes de procesarlos en memoria.

### Paso 2: Redimensionado y Conversión a WebP en el Navegador (0 costo de servidor)
- Redimensionar en el navegador usando la API nativa `HTMLCanvasElement` / `createImageBitmap` (sin dependencias pesadas, o usando `browser-image-compression`):
  - **Imágenes generales / productos / posts**: máx. `1280px` o `1600px` de lado mayor, calidad `0.80` en formato `image/webp` (peso resultante típico: **60 KB a 140 KB**).
  - **Avatares / miniaturas**: máx. `400px` x `400px`, calidad `0.80` en formato `image/webp` (peso resultante típico: **15 KB a 35 KB**).

### Paso 3: Subida con Ruta por Usuario y Caché de 1 Año
- Guarda cada archivo bajo la carpeta del `user_id` con un nombre único e inmutable:
  `{user_id}/{timestamp}-{randomId}.webp`
- **Crítico para ahorrar Egress**: configura siempre `cacheControl: '31536000'` (1 año) y `upsert: false`. Al usar nombres únicos por subida, el CDN cachea la imagen por 1 año sin consumir transferencia de origen.

### Paso 4: Limpieza de Huérfanos al Reemplazar o Borrar
- Guarda siempre en la tabla SQL tanto `image_url` (para mostrar en `<img loading="lazy" decoding="async" />`) como `image_path` (para ejecutar `supabase.storage.from('images').remove([oldPath])` cuando el usuario cambie o elimine el registro, liberando espacio del Free Tier).

Consulta todo el código TypeScript y SQL listo para copiar en [references/image-pipeline-code.md](./references/image-pipeline-code.md).
