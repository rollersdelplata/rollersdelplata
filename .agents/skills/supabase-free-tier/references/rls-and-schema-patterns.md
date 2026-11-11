# Patrones SQL de Esquema y RLS para Supabase Free Tier

Copia y adapta estas plantillas al crear migraciones en `supabase/migrations/` o scripts SQL para el SQL Editor de Supabase.

---

## 1. Tabla de Perfiles vinculada automáticamente a `auth.users`

```sql
-- 1. Crear tabla de perfiles liviana
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Habilitar RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Políticas RLS optimizadas con (SELECT auth.uid())
CREATE POLICY "Perfiles visibles públicamente"
  ON public.profiles FOR SELECT
  USING ( true );

CREATE POLICY "Usuarios pueden actualizar su propio perfil"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING ( (SELECT auth.uid()) = id )
  WITH CHECK ( (SELECT auth.uid()) = id );

-- 4. Trigger para crear el perfil automáticamente al registrarse un usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'avatar_url'
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

---

## 2. Plantilla de Tabla de Contenido con Imágenes e Índices

```sql
CREATE TABLE IF NOT EXISTS public.items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE DEFAULT auth.uid(),
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 1 AND 160),
  description TEXT,
  image_url TEXT,      -- URL pública optimizada (WebP)
  image_path TEXT,     -- Ruta interna en el bucket (ej: "<user_id>/170000-foto.webp") para poder borrarla
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices esenciales para rendimiento y RLS
CREATE INDEX IF NOT EXISTS idx_items_user_id ON public.items(user_id);
CREATE INDEX IF NOT EXISTS idx_items_published_created ON public.items(is_published, created_at DESC);

-- Habilitar RLS
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- Lectura: cualquiera ve los publicados; el dueño ve también sus borradores
CREATE POLICY "Lectura de items publicados o propios"
  ON public.items FOR SELECT
  USING ( is_published = true OR (SELECT auth.uid()) = user_id );

-- Creación: solo usuarios autenticados asignando su propio user_id
CREATE POLICY "Usuarios autenticados crean sus propios items"
  ON public.items FOR INSERT
  TO authenticated
  WITH CHECK ( (SELECT auth.uid()) = user_id );

-- Edición: solo el propietario
CREATE POLICY "Usuarios editan sus propios items"
  ON public.items FOR UPDATE
  TO authenticated
  USING ( (SELECT auth.uid()) = user_id )
  WITH CHECK ( (SELECT auth.uid()) = user_id );

-- Eliminación: solo el propietario
CREATE POLICY "Usuarios eliminan sus propios items"
  ON public.items FOR DELETE
  TO authenticated
  USING ( (SELECT auth.uid()) = user_id );
```
