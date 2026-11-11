/**
 * Comprime y redimensiona imágenes en el navegador a formato WebP antes de subirlas
 * a Supabase Storage (1 GB gratis) o Cloudflare R2 (10 GB gratis sin egress).
 */

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/avif'];
const MAX_INPUT_BYTES = 10 * 1024 * 1024; // 10 MB

export interface CompressOptions {
  maxDimension?: number;
  quality?: number;
}

export async function compressImageToWebP(
  file: File,
  options: CompressOptions = {}
): Promise<Blob> {
  if (!ALLOWED_TYPES.includes(file.type)) {
    throw new Error('Formato no soportado. Usa JPG, PNG, WebP o AVIF.');
  }
  if (file.size > MAX_INPUT_BYTES) {
    throw new Error('El archivo supera el límite máximo de 10 MB.');
  }

  const maxDimension = options.maxDimension ?? 1600;
  const quality = options.quality ?? 0.8;

  const bitmap = await createImageBitmap(file);
  let { width, height } = bitmap;

  if (width > maxDimension || height > maxDimension) {
    if (width >= height) {
      height = Math.round((height * maxDimension) / width);
      width = maxDimension;
    } else {
      width = Math.round((width * maxDimension) / height);
      height = maxDimension;
    }
  }

  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    bitmap.close();
    throw new Error('No se pudo inicializar el contexto 2D del navegador.');
  }

  ctx.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          reject(new Error('Error al comprimir la imagen a WebP.'));
          return;
        }
        resolve(blob);
      },
      'image/webp',
      quality
    );
  });
}
