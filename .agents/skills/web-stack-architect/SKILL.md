---
name: web-stack-architect
description: >-
  Usa este skill cuando el usuario quiera crear, planificar o estructurar un sitio o aplicación
  web utilizando GitHub, Cloudflare (Pages/Workers/R2) y Supabase en sus planes gratuitos (Free Tier).
  Guía la elección del framework (Astro, Vite+React o Next.js), estructura de carpetas, variables de
  entorno y optimización de cuotas gratuitas.
---

# Web Stack Architect (GitHub + Cloudflare + Supabase Free Tier)

Este skill define la arquitectura base para desarrollar sitios y aplicaciones web modernas, rápidas y escalables con **costo $0** aprovechando los tiers gratuitos de **GitHub**, **Cloudflare** y **Supabase**.

---

## 1. Matriz de Selección del Framework Frontend

Antes de inicializar el proyecto, elige (o recomienda al usuario) la opción ideal según el tipo de web:

| Tipo de Proyecto | Stack Recomendado | Por qué en Cloudflare Free Tier |
| :--- | :--- | :--- |
| **Landing pages, sitios corporativos, blogs, portfolios o catálogos con alto SEO** | **Astro + Tailwind CSS + TypeScript** (con islas de React si hay secciones interactivas) | Genera HTML estático ultra rápido (builds ilimitados y ancho de banda ilimitado gratis en Cloudflare Pages) y permite endpoints serverless puntuales. |
| **Aplicaciones interactivas, paneles (Dashboards), SaaS internos, CRMs o apps con login** | **React + Vite + Tailwind CSS + TypeScript** | Build instantáneo, 100% estático en Cloudflare Pages (0 consumo de cuota de Workers para navegar) y conexión directa desde el cliente a Supabase con RLS. |
| **Apps Full-Stack con SSR dinámico, SEO por ruta autenticada o API Routes complejas** | **Next.js (App Router) + Tailwind CSS** (con `@opennextjs/cloudflare` o `@cloudflare/next-on-pages`) | Permite SSR en el Edge de Cloudflare Workers/Pages respetando el límite de 100,000 requests/día del plan gratuito. |

---

## 2. Reglas de Oro para No Superar el Free Tier

Consulta siempre [references/free-tier-limits.md](./references/free-tier-limits.md) para los topes exactos. Aplica por defecto estas decisiones de arquitectura:

1. **Servir todo el Frontend como activo estático en Cloudflare Pages**:
   - En Cloudflare Pages, el ancho de banda (bandwidth) y las peticiones a archivos estáticos (`.html`, `.js`, `.css`, imágenes estáticas del repo) son **ilimitados y gratuitos**.
   - Reserva los Cloudflare Workers / Pages Functions únicamente para lógica que requiera secretos del servidor (webhooks, firmado de URLs de R2 o llamadas a APIs externas con API Key privada).
2. **Conexión Directa Cliente -> Supabase protegida con RLS**:
   - No crees un backend intermedio innecesario para hacer un CRUD simple si puedes llamar a Supabase directamente desde el frontend usando la `ANON_KEY` pública y **Row Level Security (RLS)** estricto en PostgreSQL (usa el skill `supabase-free-tier`).
3. **Imágenes comprimidas en el navegador antes de subir**:
   - Nunca permitas subir fotos crudas de celular/cámara (3 MB a 10 MB) directo al almacenamiento. Aplica siempre el flujo del skill `image-upload-optimizer` (compresión a WebP en cliente + caché agresiva en CDN).
4. **Prevención de pausa en Supabase Free Tier**:
   - Los proyectos gratuitos de Supabase se pausan tras 7 días sin actividad. Incluye siempre el workflow de GitHub Actions de *Keep-Alive* documentado en el skill `supabase-free-tier`.

---

## 3. Estructura Base del Proyecto y Variables de Entorno

Al inicializar un proyecto web:

1. Crea un archivo `.env.example` (commiteado a Git) y un `.env` o `.dev.vars` (ignorado en `.gitignore`):
   ```env
   # Supabase (Públicas para el cliente - seguras solo con RLS activo)
   PUBLIC_SUPABASE_URL=https://tu-proyecto.supabase.co
   PUBLIC_SUPABASE_ANON_KEY=tu-anon-key-publica

   # Nota: En Vite usa el prefijo VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY
   # En Next.js usa NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_ANON_KEY
   ```
2. Verifica que `.gitignore` excluya siempre:
   - `node_modules/`, `dist/`, `.astro/`, `.next/`, `.wrangler/`
   - `.env`, `.env.*` (excepto `.env.example`), `.dev.vars`
3. Configura el cliente de Supabase como un singleton reutilizable en `src/lib/supabase.ts`.
