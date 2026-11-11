---
name: supabase-free-tier
description: >-
  Usa este skill para diseñar tablas PostgreSQL, configurar autenticación, escribir políticas
  Row Level Security (RLS), optimizar consultas para cuidar los 500MB de DB y 5GB de egress del
  plan gratuito de Supabase, y configurar el cron Keep-Alive en GitHub Actions para evitar pausas por inactividad.
---

# Supabase Free Tier — Base de Datos, Auth, RLS y Optimización

Este skill guía toda implementación de backend sobre el **Plan Gratuito de Supabase** garantizando seguridad desde el día uno y evitando agotar las cuotas gratuitas.

---

## 1. Reglas Innegociables de Seguridad (RLS)

En nuestra arquitectura serverless, el frontend se conecta directamente a Supabase usando la `ANON_KEY`. Por lo tanto:

1. **Toda tabla en el esquema `public` DEBE tener RLS habilitado inmediatamente después de `CREATE TABLE`**:
   ```sql
   ALTER TABLE public.nombre_tabla ENABLE ROW LEVEL SECURITY;
   ```
2. **Principio de mínimo privilegio**:
   - Separa las políticas por operación (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) en lugar de usar `FOR ALL` indiscriminadamente.
   - Para `INSERT` y `UPDATE`, incluye siempre la cláusula `WITH CHECK (...)` validando que `auth.uid() = user_id`.
3. **Rendimiento en políticas RLS**:
   - Envuelve `auth.uid()` como `(SELECT auth.uid())` dentro de las políticas RLS para que PostgreSQL cachee el valor por consulta (InitPlan) en lugar de evaluarlo fila por fila:
     ```sql
     USING ( (SELECT auth.uid()) = user_id )
     ```
   - Crea siempre un **índice (`CREATE INDEX`)** sobre cualquier columna usada en una política RLS (como `user_id`) o en filtros frecuentes (`WHERE`, `ORDER BY`).

Consulta los patrones SQL listos para usar en [references/rls-and-schema-patterns.md](./references/rls-and-schema-patterns.md).

---

## 2. Optimización para Cuidar los 500 MB de DB y 5 GB de Egress

1. **Prohibido `select('*')` en listados**:
   - Selecciona únicamente las columnas que la vista necesita renderizar:
     ```ts
     const { data, error } = await supabase
       .from('products')
       .select('id, title, price, thumbnail_url')
       .eq('is_active', true)
       .order('created_at', { ascending: false })
       .range(0, 19); // Paginación obligatoria
     ```
2. **Solo URLs de imágenes en la Base de Datos**:
   - Jamás almacenes imágenes codificadas en Base64 ni columnas `bytea` en PostgreSQL. Guarda el archivo optimizado en Supabase Storage o Cloudflare R2 y almacena únicamente el `path` o `public_url` (`text`) en la tabla.
3. **Evitar suscripciones Realtime innecesarias**:
   - El plan gratuito incluye hasta 200 conexiones concurrentes de Realtime. Úsalo solo si la funcionalidad realmente requiere tiempo real (ej. chat en vivo); para todo lo demás, usa lecturas bajo demanda con caché en cliente.

---

## 3. Prevención de Pausa por Inactividad (Keep-Alive Automático)

El plan gratuito de Supabase pausa el proyecto si no registra peticiones en **7 días**. Siempre que configures un proyecto con Supabase y GitHub, ofrece o crea este workflow en `.github/workflows/supabase-keep-alive.yml`:

```yaml
name: Supabase Free Tier Keep-Alive

on:
  schedule:
    # Se ejecuta cada 5 días a las 08:00 UTC
    - cron: '0 8 */5 * *'
  workflow_dispatch: # Permite ejecutarlo manualmente desde GitHub

jobs:
  ping-supabase:
    runs-on: ubuntu-latest
    steps:
      - name: Ping Supabase REST API
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
        run: |
          curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" \
            "${SUPABASE_URL}/rest/v1/" \
            -H "apikey: ${SUPABASE_ANON_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_ANON_KEY}"
```
> Recuérdale al usuario cargar `SUPABASE_URL` y `SUPABASE_ANON_KEY` en **GitHub -> Settings -> Secrets and variables -> Actions**.
