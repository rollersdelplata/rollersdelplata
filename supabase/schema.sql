-- Esquema base para Rollers del Plata en Supabase Free Tier (PostgreSQL + RLS)

-- 1. Tabla de Productos / Catálogo (Telas, Mecanismos, Motores)
CREATE TABLE IF NOT EXISTS public.catalogo_productos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria text NOT NULL, -- 'blackout', 'screen-5', 'blackout-texturado', 'traslucidas', 'manual', 'motorizado'
  titulo text NOT NULL,
  descripcion text,
  especificaciones jsonb DEFAULT '{}'::jsonb,
  image_url text,
  image_path text,
  orden integer DEFAULT 0,
  activo boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.catalogo_productos ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_catalogo_categoria_activo
  ON public.catalogo_productos (categoria, activo, orden);

-- Lectura pública para visitantes de la web
CREATE POLICY "Lectura pública de productos activos"
  ON public.catalogo_productos
  FOR SELECT
  USING (activo = true);

-- Administración solo para usuarios autenticados
CREATE POLICY "Admin inserta productos"
  ON public.catalogo_productos
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

CREATE POLICY "Admin actualiza productos"
  ON public.catalogo_productos
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL)
  WITH CHECK ((SELECT auth.uid()) IS NOT NULL);

CREATE POLICY "Admin elimina productos"
  ON public.catalogo_productos
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL);

-- 2. Tabla de Consultas / Presupuestos / Distribuidores
CREATE TABLE IF NOT EXISTS public.consultas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo text NOT NULL DEFAULT 'presupuesto', -- 'presupuesto' | 'distribuidor' | 'comercio'
  nombre text NOT NULL,
  email text NOT NULL,
  telefono text,
  localidad text,
  mensaje text NOT NULL,
  leido boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.consultas ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_consultas_created_at
  ON public.consultas (created_at DESC);

-- Cualquier visitante puede enviar una consulta de presupuesto/distribuidor
CREATE POLICY "Visitantes pueden enviar consultas"
  ON public.consultas
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (char_length(nombre) > 1 AND char_length(email) > 3);

-- Solo administradores autenticados pueden leer las consultas
CREATE POLICY "Admin lee consultas"
  ON public.consultas
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) IS NOT NULL);
