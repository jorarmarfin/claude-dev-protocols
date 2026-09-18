# Schema del catálogo (Supabase)

Fuente: `lib/features/products/data/products_repository.dart` en
`la_huanquita_admin` (proyecto Flutter). Soft-delete vía `active` en todas —
nunca borrado físico, hay FKs desde `product_variants`.

## colors
- `id` (uuid, pk)
- `name` (text)
- `hex_code` (text, nullable, ej `#FF0000`)
- `active` (bool)

## sizes
- `id` (uuid, pk)
- `name` (text)
- `sort_order` (int)
- `active` (bool)

## categories
- `id` (uuid, pk)
- `name` (text)
- `sort_order` (int)
- `active` (bool)

## products
- `id` (uuid, pk)
- `code` (text, único — validado a mano antes de insert/update)
- `name` (text)
- `description` (text, nullable)
- `price` (numeric, **nullable** — precio de referencia; el precio real de
  cada venta vive en `order_items.unit_price`, independiente de este campo,
  así que null aquí significa "a cotizar con el cliente", no un error).
  Requiere migración `ALTER TABLE products ALTER COLUMN price DROP NOT NULL`
  si la columna todavía es `NOT NULL` en la DB.
- `cover_image_path` (text, nullable — fuera de alcance de este skill, se
  sube desde la app)
- `active` (bool)
- `featured` (bool)
- `category_id` (uuid, fk → categories.id, nullable)
- `created_at` (timestamp, default de la DB)

## product_variants
- `id` (uuid, pk)
- `product_id` (uuid, fk → products.id)
- `color_id` (uuid, fk → colors.id)
- `size_id` (uuid, fk → sizes.id)
- `stock` (int)
- `availability_status` (text: `available` | `low_stock` | `out_of_stock`)
- `active` (bool)
- Constraint única de facto sobre `(product_id, color_id, size_id)` — el
  upsert usa `on_conflict` con esas tres columnas.
