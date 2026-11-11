# Rollers del Plata — Sitio Web Oficial

Sitio web oficial de **Rollers del Plata** (Fábrica de Cortinas Enrollables en San Isidro, Buenos Aires), migrado desde Google Sites a una arquitectura moderna y ultra rápida en **Astro + Tailwind CSS + TypeScript + Supabase**, optimizada para ejecutarse con **costo $0** sobre **Cloudflare Pages** y **Supabase Free Tier**.

---

## 🗺️ Mapa del Sitio (11 Páginas Migradas 1:1)

- `/` y `/inicio`: Portada institucional, carrusel de 7 instalaciones destacadas, grilla de los 4 géneros principales, sección de motorización Somfy/Inteo, convocatoria para comercios/profesionales/showrooms y redes sociales.
- `/catalogo`: Presentación de muestrarios, acceso a las 4 líneas de telas y catálogo digital interactivo embebido.
  - `/catalogo/fotos-cortinas-black-out`: Galería en carrusel de cortinas Black Out (6 fotos).
  - `/catalogo/fotos-cortinas-screen-5`: Galería en carrusel de cortinas Screen 5% (7 fotos).
  - `/catalogo/fotos-cortinas-black-out-texturado`: Galería en carrusel de cortinas Black Out Texturado (5 fotos).
  - `/catalogo/fotos-cortinas-traslucidas`: Galería en carrusel de cortinas Traslúcidas (7 fotos).
- `/servicios`: Guía de asesoramiento técnico (*"A tener en cuenta..."*, *"Estudiar cuál es la mejor opción..."*, esquema de tipos de caída y posición de accionamiento, *"Tenemos soluciones..."* con muestrario de 9 variantes y formulario para distribuidores).
- `/accionamientos`: Selector visual de sistemas Manual y Motorizado.
  - `/accionamientos/manual`: Especificaciones técnicas, planos de medidas y enlaces de componentes para Mecanismo 25 mm, 32 mm, 38 mm y 41 mm Plus.
  - `/accionamientos/motorizado`: Soluciones de automatización y domótica **Somfy Argentina** (*Inteo*, *Sonesse 40/50* y *Tube by Somfy 6/28-40 y 10/28-50*).
- `/clientes`: Acceso directo a Linktree oficial, redes y contacto.

---

## 🚀 Comandos de Desarrollo Local

```bash
# Instalar dependencias
npm install

# Iniciar servidor de desarrollo (http://localhost:4321)
npm run dev

# Generar build estático de producción en /dist
npm run build
```

---

## ☁️ Despliegue en Cloudflare Pages (Free Tier)

1. Ingresa a **Cloudflare Dashboard -> Workers & Pages -> Create -> Pages -> Connect to Git**.
2. Selecciona el repositorio `rollersdelplata/rollersdelplata`.
3. Configura los parámetros de compilación:
   - **Framework preset**: `Astro`
   - **Build command**: `npm run build`
   - **Build output directory**: `dist`
4. *(Opcional, cuando actives Supabase)* Agrega las variables de entorno `PUBLIC_SUPABASE_URL` y `PUBLIC_SUPABASE_ANON_KEY`.
