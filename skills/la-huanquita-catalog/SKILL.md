---
name: la-huanquita-catalog
description: Crea y administra colores, tallas, categorías, productos y variantes del proyecto La Huanquita directo contra la API REST de Supabase (sin backend intermedio — este proyecto y la app móvil hablan directo a Supabase). Úsalo cuando el usuario pida subir/crear/actualizar colores, tallas, categorías o productos por lotes, o quiera que un agente alimente el catálogo sin pasar por la UI de Flutter.
metadata:
  short-description: CRUD de colores/tallas/productos vía API REST de Supabase
---

# La Huanquita — Catálogo vía API

Este skill administra las tablas `colors`, `sizes`, `categories`, `products` y
`product_variants` del proyecto Supabase de **La Huanquita** (mismo backend
que usan `la_huanquita_admin` y la app móvil `la_huanquita` — no hay un
servidor intermedio propio: Supabase ES el backend, vía su API REST
autogenerada, PostgREST).

## Por qué service role key y no login admin

Las tablas tienen RLS con policies `*_write_admin` que solo dejan escribir a
un usuario admin autenticado. Para automatización se usa en su lugar la
**service role key** de Supabase, que bypassa RLS por completo. Por eso:

- Esta clave **nunca** se comparte, comitea, ni se usa desde nada que no sea
  esta máquina en modo local. Si el usuario la pega en el chat, úsala solo
  para esa ejecución y no la repitas en tu respuesta ni la escribas en
  archivos del repo del proyecto.
- Como bypassa RLS, el script hace a mano la única validación que la app sí
  aplica (código de producto único) — no asumas que hay más validaciones del
  lado del servidor.

## Credenciales

En este orden de prioridad:

1. `--base-url` / `--service-key` en la línea de comandos.
2. Variables de entorno `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`.
3. Archivo `~/.claude/skills/la-huanquita-catalog/credentials` (o el que
   pases con `--credentials`):

   ```
   baseUrl=https://xxxxx.supabase.co
   service_role_key=eyJ...
   ```

   Ese archivo vive fuera de cualquier repo git — no lo muevas al proyecto.
   La service role key se obtiene en el dashboard de Supabase del proyecto
   (Project Settings → API → `service_role` secret), nunca es la misma que
   `SUPABASE_ANON_KEY` del `.env` de la app.

Si no hay credenciales disponibles, pídeselas al usuario — no las inventes
ni asumas un proyecto Supabase por defecto.

## Comandos

Todos devuelven JSON de la(s) fila(s) afectada(s).

```bash
S=~/.claude/skills/la-huanquita-catalog/scripts/catalog_api.py

# Colores
python3 $S colors list
python3 $S colors create --name "Rojo" --hex "#FF0000"
python3 $S colors update <id> --name "Rojo intenso" --hex "#CC0000"
python3 $S colors set-active <id> --active false   # soft-delete, nunca borrado físico (FK desde variants)

# Tallas
python3 $S sizes list
python3 $S sizes create --name "M" --sort-order 2
python3 $S sizes set-active <id> --active false

# Categorías
python3 $S categories list
python3 $S categories create --name "Polos" --sort-order 1

# Productos — el precio es opcional: sin --price el producto queda "a cotizar"
# (el precio real se define recién al armar el pedido de cada cliente, en
# order_items.unit_price, que es independiente de products.price)
python3 $S products list
python3 $S products create --code "POL-001" --name "Polo básico" \
  --description "Polo de algodón" --category-id <categoria_id> --active true
python3 $S products create --code "POL-002" --name "Polo premium" --price 39.90  # con precio de referencia, si aplica
python3 $S products update <id> --price 45.00 --featured true

# Variantes (color × talla × stock) — upsert, no duplica si ya existe la combinación
python3 $S variants set <product_id> --color-id <id> --size-id <id> --stock 10 --status available
# --status: available | low_stock | out_of_stock
```

## Flujo recomendado para "subir productos"

1. `colors list` y `sizes list` (y `categories list` si aplica) para obtener
   los IDs existentes — **nunca inventes IDs**, y si el color/talla que pide
   el usuario no existe, créalo primero con `colors create` / `sizes create`.
2. `products create` con el código, nombre y precio.
3. Por cada combinación color×talla que tenga el producto, `variants set`
   con el `product_id` devuelto en el paso 2.

Si el usuario da una lista/CSV de productos, procesa fila por fila con este
mismo flujo — confirma con él antes de crear en lote si son más de ~10
productos, para evitar tener que revertir un error masivo a mano.

## Notas de schema

Ver `references/schema.md` para las columnas exactas de cada tabla (extraídas
de `lib/features/products/data/products_repository.dart` en
`la_huanquita_admin`, la fuente de verdad de este catálogo).
