# Código Listo para Usar: Compresión WebP, Subida y Políticas de Storage

## 1. Compresor Nativo a WebP en el Navegador (0 Librerías Externas)

Crea este archivo en `src/lib/imageOptimizer.ts`:

```ts
export interface OptimizeImageOptions {
  maxWidthOrHeight?: number;
  quality?: number; // 0.1 a 1.0 (recomendado: 0.8)
}

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/avif'];
const MAX_RAW_SIZE_BYTES = 10 * 1024 * 1024; // 10 MB de entrada máxima

/**
 * Redimensiona y convierte cualquier imagen a formato WebP en el navegador
 * reduciendo imágenes de 5MB a ~80-140KB sin costo de servidor.
 */
export async function compressImageToWebP(
  file: File,
  options: OptimizeImageOptions = {}
): Promise<File> {
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Formato no soportado. Usa imágenes JPG, PNG, WebP o AVIF.');
  }
  if (file.size > MAX_RAW_SIZE_BYTES) {
    throw new Error('La imagen original supera el límite de 10 MB.');
  }

  const maxDim = options.maxWidthOrHeight ?? 1400;
  const quality = options.quality ?? 0.8;

  const bitmap = await createImageBitmap(file);
  let { width, height } = bitmap;

  if (width > maxDim || height > maxDim) {
    if (width > height) {
      height = Math.round((height * maxDim) / width);
      width = maxDim;
    } else {
      width = Math.round((width * maxDim) / height);
      height = maxDim;
    }
  }

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;

  const ctx = canvas.getContext('2d');
  if (!ctx) {
    bitmap.close();
    throw new Error('No se pudo inicializar el contexto gráfico para comprimir la imagen.');
  }

  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  const blob: Blob = await new Promise((resolve, reject) => {
    canvas.toBlob(
      (result) => (result ? resolve(result) : reject(new Error('Error al generar archivo WebP.'))),
      'image/webp',
      quality
    );
  });

  const cleanName = file.name.replace(/\.[^/.]+$/, '').replace(/[^a-zA-Z0-9-_]/g, '-');
  return new File([blob], `${cleanName}.webp`, {
    type: 'image/webp',
    lastModified: Date.now(),
  });
}
```

---

## 2. Helper de Subida y Borrado en Supabase Storage (`src/lib/storage.ts`)

```ts
import { supabase } from './supabase';
import { compressImageToWebP, type OptimizeImageOptions } from './imageOptimizer';

const BUCKET_NAME = 'images';

export interface UploadResult {
  publicUrl: string;
  storagePath: string;
  sizeKB: number;
}

export async function uploadOptimizedImage(
  rawFile: File,
  userId: string,
  options?: OptimizeImageOptions
): Promise<UploadResult> {
  // 1. Comprimir a WebP en el cliente
  const webpFile = await compressImageToWebP(rawFile, options);

  // 2. Generar ruta aislada por usuario e inmutable para caché de 1 año
  const uniqueId = crypto.randomUUID ? crypto.randomUUID().slice(0, 8) : Math.random().toString(36).slice(2, 10);
  const storagePath = `${userId}/${Date.now()}-${uniqueId}.webp`;

  // 3. Subir a Supabase Storage con cacheControl de 1 año (ahorra Egress)
  const { error: uploadError } = await supabase.storage
    .from(BUCKET_NAME)
    .upload(storagePath, webpFile, {
      cacheControl: '31536000',
      contentType: 'image/webp',
      upsert: false,
    });

  if (uploadError) {
    throw new Error(`Error al subir la imagen: ${uploadError.message}`);
  }

  const { data } = supabase.storage.from(BUCKET_NAME).getPublicUrl(storagePath);

  return {
    publicUrl: data.publicUrl,
    storagePath,
    sizeKB: Math.round(webpFile.size / 1024),
  };
}

/**
 * Elimina la imagen anterior del bucket para no desperdiciar el 1 GB del Free Tier.
 */
export async function deleteStoredImage(storagePath: string | null | undefined): Promise<void> {
  if (!storagePath) return;
  await supabase.storage.from(BUCKET_NAME).remove([storagePath]);
}
```

---

## 3. SQL para Crear el Bucket `images` y Políticas RLS en Supabase

Ejecuta este SQL en el Editor SQL de Supabase o en una migración:

```sql
-- 1. Crear el bucket público 'images' restringido a formatos de imagen y máx 2 MB (ya comprimidos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images',
  'images',
  true,
  2097152, -- 2 MB máximo por imagen comprimida
  ARRAY['image/webp', 'image/jpeg', 'image/png', 'image/avif']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Política de Lectura: Cualquier visitante puede ver las imágenes públicas
CREATE POLICY "Imágenes públicas visibles para todos"
  ON storage.objects FOR SELECT
  USING ( bucket_id = 'images' );

-- 3. Política de Subida: Usuarios autenticados solo pueden subir dentro de su carpeta "<user_id>/..."
CREATE POLICY "Usuarios suben imágenes solo en su carpeta"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );

-- 4. Política de Eliminación: Usuarios solo pueden borrar imágenes de su propia carpeta
CREATE POLICY "Usuarios eliminan solo sus propias imágenes"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'images'
    AND (storage.foldername(name))[1] = (SELECT auth.uid()::text)
  );
```

---

## 4. Alternativa Cloudflare R2 (Para >1 GB y 0 Egress) vía Pages Function

Si el proyecto usa Cloudflare R2, crea una Pages Function en `functions/api/upload.ts` vinculada al bucket `IMAGES_BUCKET`:

```ts
interface Env {
  IMAGES_BUCKET: R2Bucket;
  PUBLIC_R2_DOMAIN: string; // ej. https://cdn.tudominio.com
}

export const onRequestPost: PagesFunction<Env> = async ({ request, env }) => {
  const formData = await request.formData();
  const file = formData.get('file') as File | null;

  if (!file || file.type !== 'image/webp' || file.size > 2 * 1024 * 1024) {
    return new Response(JSON.stringify({ error: 'Archivo inválido (debe ser WebP <= 2MB)' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const key = `uploads/${Date.now()}-${crypto.randomUUID().slice(0, 8)}.webp`;
  await env.IMAGES_BUCKET.put(key, await file.arrayBuffer(), {
    httpMetadata: {
      contentType: 'image/webp',
      cacheControl: 'public, max-age=31536000, immutable',
    },
  });

  return new Response(
    JSON.stringify({
      publicUrl: `${env.PUBLIC_R2_DOMAIN}/${key}`,
      storagePath: key,
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
};
```
