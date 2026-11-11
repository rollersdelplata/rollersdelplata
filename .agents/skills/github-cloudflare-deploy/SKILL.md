---
name: github-cloudflare-deploy
description: >-
  Usa este skill para configurar repositorios de GitHub, preparar archivos de configuración
  de Cloudflare Pages y Workers (wrangler.toml, _headers, _redirects), configurar variables de
  entorno y desplegar sitios web en el plan gratuito de Cloudflare.
---

# GitHub & Cloudflare Pages/Workers Deploy (Free Tier)

Este skill guía el versionado en GitHub y la puesta en producción en **Cloudflare Pages / Workers** sin costo.

---

## 1. Preparación del Proyecto para Cloudflare Pages

Antes de subir a GitHub o ejecutar el deploy, verifica que el proyecto incluya:

### A. Redirecciones para SPAs (`public/_redirects`)
Si el proyecto es una Single Page Application (Vite + React), crea `public/_redirects` para que las rutas del cliente (React Router / TanStack Router) no devuelvan 404 al recargar:
```text
/* /index.html 200
```

### B. Cabeceras de Seguridad y Caché (`public/_headers`)
Agrega `public/_headers` para proteger la web y maximizar la caché estática en Cloudflare:
```text
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin

/assets/*
  Cache-Control: public, max-age=31536000, immutable
```

### C. Configuración de `wrangler.toml` (Workers Static Assets / Pages / R2)
> **Regla crítica para Wrangler v4 (`npx wrangler deploy`)**: El flujo por defecto de Cloudflare al conectar Git ejecuta `npx wrangler deploy`. **NUNCA uses `pages_build_output_dir = "dist"`** porque falla con `Missing entry-point to Worker script or to assets directory`. Usa **siempre** el bloque `[assets] directory = "./dist"`:

```toml
name = "nombre-del-proyecto"
compatibility_date = "2026-01-01"

[assets]
directory = "./dist"

# Descomentar solo si se usa Cloudflare R2 para imágenes:
# [[r2_buckets]]
# binding = "IMAGES_BUCKET"
# bucket_name = "nombre-bucket-imagenes"
```

---

## 2. Parámetros de Build según el Framework en Cloudflare Pages

Cuando se conecta el repositorio de GitHub a Cloudflare Pages (o al configurar el proyecto), utiliza estos valores:

| Framework | Comando de Build | Directorio de Salida (`Output directory`) | Variable `NODE_VERSION` |
| :--- | :--- | :--- | :--- |
| **Astro** | `npm run build` | `dist` | `20` o `22` |
| **Vite + React** | `npm run build` | `dist` | `20` o `22` |
| **Next.js (`@cloudflare/next-on-pages`)** | `npx @cloudflare/next-on-pages@1` | `.vercel/output/static` | `20` o `22` |

---

## 3. Flujo Paso a Paso de Publicación (GitHub + Cloudflare)

1. **Verificación previa al commit**:
   - Corre `npm run build` localmente para confirmar que no hay errores de TypeScript ni de empaquetado.
   - Confirma que `.env` y `.dev.vars` **no** estén siendo trackeados por `git status`.
2. **Repositorio en GitHub**:
   - Inicializa Git (`git init`, `git branch -M main`) y sube el repositorio (con `gh repo create <nombre> --private --source=. --push` si `gh` está autenticado, o conectando el `origin` remoto).
3. **Despliegue en Cloudflare Pages**:
   - **Vía integración Git (Recomendado)**: Conectar el repo en el dashboard de Cloudflare (`Workers & Pages -> Create -> Pages -> Connect to Git`), definir las variables de entorno de Supabase (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` o `PUBLIC_SUPABASE_*`) y hacer push a `main`.
   - **Vía CLI directa (`wrangler`)**:
     ```bash
     npx wrangler pages deploy dist --project-name=<nombre-del-proyecto>
     ```
4. **Configuración en Supabase Auth (URL Configuration)**:
   - Recuérdale siempre al usuario agregar el dominio `.pages.dev` (y su dominio personalizado si tiene) en **Supabase Dashboard -> Authentication -> URL Configuration** (`Site URL` y `Redirect URLs`).
