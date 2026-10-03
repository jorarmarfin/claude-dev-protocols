#!/usr/bin/env python3
"""CRUD directo contra las tablas colors/sizes/categories/products/product_variants
del proyecto Supabase de La Huanquita, vía su API REST autogenerada (PostgREST).

No hay backend intermedio: este proyecto y la app móvil `la_huanquita` hablan
directo contra Supabase. Este script usa la SERVICE ROLE KEY (bypassa RLS),
así que solo debe correrse localmente, nunca desde un servicio expuesto.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid
from pathlib import Path

VALID_AVAILABILITY = {"available", "low_stock", "out_of_stock"}
IMAGES_BUCKET = "product-images"


def parse_key_values(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    raw = path.read_text(encoding="utf-8").strip()
    if raw.startswith("{"):
        data = json.loads(raw)
        return {str(k): str(v) for k, v in data.items() if v is not None}
    values: dict[str, str] = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        match = re.match(r"@?([A-Za-z0-9_.-]+)\s*(?:=|:)\s*(.*)$", line)
        if not match:
            continue
        key, value = match.groups()
        values[key] = value.strip().strip('"').strip("'")
    return values


def pick(values: dict[str, str], *keys: str) -> str | None:
    lowered = {k.lower(): v for k, v in values.items()}
    for key in keys:
        value = values.get(key) or lowered.get(key.lower())
        if value:
            return value
    return None


def normalize_base_url(value: str) -> str:
    value = value.strip().rstrip("/")
    if not re.match(r"^https?://", value):
        value = "https://" + value
    return value


def resolve_credentials(args: argparse.Namespace) -> tuple[str, str]:
    creds_path = Path(args.credentials or (Path.home() / ".claude" / "skills" / "la-huanquita-catalog" / "credentials"))
    file_values = parse_key_values(creds_path)

    service_key = (
        args.service_key
        or os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
        or pick(file_values, "service_role_key", "SUPABASE_SERVICE_ROLE_KEY")
    )
    base_url = (
        args.base_url
        or os.environ.get("SUPABASE_URL")
        or pick(file_values, "baseUrl", "SUPABASE_URL")
    )

    if not service_key:
        raise SystemExit(
            "Falta la service role key. Pásala con --service-key, la variable "
            "SUPABASE_SERVICE_ROLE_KEY, o en el archivo de credenciales "
            f"({creds_path})."
        )
    if not base_url:
        raise SystemExit(
            "Falta la URL de Supabase. Pásala con --base-url, la variable "
            f"SUPABASE_URL, o en el archivo de credenciales ({creds_path})."
        )
    return normalize_base_url(base_url), service_key


def rest_request(
    base_url: str,
    service_key: str,
    method: str,
    table: str,
    *,
    query: dict[str, str] | None = None,
    body: dict | list | None = None,
    prefer: str = "return=representation",
) -> object:
    url = f"{base_url}/rest/v1/{table}"
    if query:
        url += "?" + urllib.parse.urlencode(query, safe=",.")

    headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": "application/json",
        "Prefer": prefer,
    }
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, method=method, headers=headers, data=data)
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} en {method} {table}: {e.read().decode()}")


def storage_upload(base_url: str, service_key: str, storage_path: str, file_path: Path) -> None:
    mime_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    url = f"{base_url}/storage/v1/object/{IMAGES_BUCKET}/{storage_path}"
    headers = {
        "apikey": service_key,
        "Authorization": f"Bearer {service_key}",
        "Content-Type": mime_type,
        "x-upsert": "true",
    }
    req = urllib.request.Request(url, method="POST", headers=headers, data=file_path.read_bytes())
    try:
        with urllib.request.urlopen(req):
            pass
    except urllib.error.HTTPError as e:
        raise SystemExit(f"HTTP {e.code} subiendo imagen a Storage: {e.read().decode()}")


def public_image_url(base_url: str, storage_path: str) -> str:
    return f"{base_url}/storage/v1/object/public/{IMAGES_BUCKET}/{storage_path}"


def print_json(data: object) -> None:
    print(json.dumps(data, indent=2, ensure_ascii=False))


def cmd_colors(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.action == "list":
        rows = rest_request(base_url, key, "GET", "colors", query={"select": "id,name,hex_code,active", "order": "name"})
        print_json(rows)
    elif args.action == "create":
        body = {"name": args.name, "hex_code": args.hex, "active": True}
        rows = rest_request(base_url, key, "POST", "colors", body=body)
        print_json(rows)
    elif args.action == "update":
        body = {k: v for k, v in {"name": args.name, "hex_code": args.hex}.items() if v is not None}
        if not body:
            raise SystemExit("Nada que actualizar: pasa --name y/o --hex.")
        rows = rest_request(base_url, key, "PATCH", "colors", query={"id": f"eq.{args.id}"}, body=body)
        print_json(rows)
    elif args.action == "set-active":
        rows = rest_request(base_url, key, "PATCH", "colors", query={"id": f"eq.{args.id}"}, body={"active": args.active})
        print_json(rows)


def cmd_sizes(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.action == "list":
        rows = rest_request(base_url, key, "GET", "sizes", query={"select": "id,name,sort_order,active", "order": "sort_order"})
        print_json(rows)
    elif args.action == "create":
        body = {"name": args.name, "sort_order": args.sort_order, "active": True}
        rows = rest_request(base_url, key, "POST", "sizes", body=body)
        print_json(rows)
    elif args.action == "update":
        body = {k: v for k, v in {"name": args.name, "sort_order": args.sort_order}.items() if v is not None}
        if not body:
            raise SystemExit("Nada que actualizar: pasa --name y/o --sort-order.")
        rows = rest_request(base_url, key, "PATCH", "sizes", query={"id": f"eq.{args.id}"}, body=body)
        print_json(rows)
    elif args.action == "set-active":
        rows = rest_request(base_url, key, "PATCH", "sizes", query={"id": f"eq.{args.id}"}, body={"active": args.active})
        print_json(rows)


def cmd_categories(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.action == "list":
        rows = rest_request(base_url, key, "GET", "categories", query={"select": "id,name,sort_order,active", "order": "sort_order"})
        print_json(rows)
    elif args.action == "create":
        body = {"name": args.name, "sort_order": args.sort_order, "active": True}
        rows = rest_request(base_url, key, "POST", "categories", body=body)
        print_json(rows)


def code_exists(base_url: str, key: str, code: str, excluding_id: str | None = None) -> bool:
    query = {"select": "id", "code": f"eq.{code}"}
    rows = rest_request(base_url, key, "GET", "products", query=query)
    rows = rows or []
    if excluding_id:
        rows = [r for r in rows if r.get("id") != excluding_id]
    return len(rows) > 0


def cmd_products(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.action == "list":
        rows = rest_request(
            base_url, key, "GET", "products",
            query={"select": "id,code,name,price,active,featured,category_id", "order": "created_at.desc"},
        )
        print_json(rows)
    elif args.action == "create":
        if code_exists(base_url, key, args.code):
            raise SystemExit(f"El código de producto '{args.code}' ya existe.")
        body = {
            "code": args.code,
            "name": args.name,
            "description": args.description,
            "price": args.price,
            "featured": args.featured,
            "active": args.active,
            "category_id": args.category_id,
        }
        rows = rest_request(base_url, key, "POST", "products", body=body)
        print_json(rows)
    elif args.action == "update":
        if args.code and code_exists(base_url, key, args.code, excluding_id=args.id):
            raise SystemExit(f"El código de producto '{args.code}' ya existe en otro producto.")
        body = {
            k: v
            for k, v in {
                "code": args.code,
                "name": args.name,
                "description": args.description,
                "price": args.price,
                "featured": args.featured,
                "active": args.active,
                "category_id": args.category_id,
            }.items()
            if v is not None
        }
        if not body:
            raise SystemExit("Nada que actualizar.")
        rows = rest_request(base_url, key, "PATCH", "products", query={"id": f"eq.{args.id}"}, body=body)
        print_json(rows)


def cmd_images(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.action != "upload":
        return
    file_path = Path(args.file).expanduser()
    if not file_path.exists():
        raise SystemExit(f"Archivo no encontrado: {file_path}")

    extension = file_path.suffix.lstrip(".").lower() or "jpg"
    storage_path = f"products/{args.product_id}/{uuid.uuid4()}.{extension}"
    storage_upload(base_url, key, storage_path, file_path)

    row = rest_request(
        base_url, key, "POST", "product_images",
        body={"product_id": args.product_id, "storage_path": storage_path, "sort_order": args.sort_order},
    )

    if args.cover:
        rest_request(
            base_url, key, "PATCH", "products",
            query={"id": f"eq.{args.product_id}"},
            body={"cover_image_path": storage_path},
        )

    print_json({"storage_path": storage_path, "public_url": public_image_url(base_url, storage_path), "row": row})


def cmd_variants(args: argparse.Namespace) -> None:
    base_url, key = resolve_credentials(args)
    if args.status not in VALID_AVAILABILITY:
        raise SystemExit(f"--status debe ser uno de: {', '.join(sorted(VALID_AVAILABILITY))}")
    body = {
        "product_id": args.product_id,
        "color_id": args.color_id,
        "size_id": args.size_id,
        "stock": args.stock,
        "availability_status": args.status,
        "active": True,
    }
    rows = rest_request(
        base_url, key, "POST", "product_variants",
        query={"on_conflict": "product_id,color_id,size_id"},
        body=body,
        prefer="resolution=merge-duplicates,return=representation",
    )
    print_json(rows)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", help="URL del proyecto Supabase (o env SUPABASE_URL)")
    parser.add_argument("--service-key", help="Service role key (o env SUPABASE_SERVICE_ROLE_KEY)")
    parser.add_argument("--credentials", help="Ruta a archivo de credenciales alterno")

    sub = parser.add_subparsers(dest="entity", required=True)

    colors = sub.add_parser("colors")
    colors_sub = colors.add_subparsers(dest="action", required=True)
    colors_sub.add_parser("list").set_defaults(func=cmd_colors)
    c_create = colors_sub.add_parser("create")
    c_create.add_argument("--name", required=True)
    c_create.add_argument("--hex")
    c_create.set_defaults(func=cmd_colors)
    c_update = colors_sub.add_parser("update")
    c_update.add_argument("id")
    c_update.add_argument("--name")
    c_update.add_argument("--hex")
    c_update.set_defaults(func=cmd_colors)
    c_active = colors_sub.add_parser("set-active")
    c_active.add_argument("id")
    c_active.add_argument("--active", type=lambda v: v.lower() in ("1", "true", "yes"), required=True)
    c_active.set_defaults(func=cmd_colors)

    sizes = sub.add_parser("sizes")
    sizes_sub = sizes.add_subparsers(dest="action", required=True)
    sizes_sub.add_parser("list").set_defaults(func=cmd_sizes)
    s_create = sizes_sub.add_parser("create")
    s_create.add_argument("--name", required=True)
    s_create.add_argument("--sort-order", type=int, required=True)
    s_create.set_defaults(func=cmd_sizes)
    s_update = sizes_sub.add_parser("update")
    s_update.add_argument("id")
    s_update.add_argument("--name")
    s_update.add_argument("--sort-order", type=int)
    s_update.set_defaults(func=cmd_sizes)
    s_active = sizes_sub.add_parser("set-active")
    s_active.add_argument("id")
    s_active.add_argument("--active", type=lambda v: v.lower() in ("1", "true", "yes"), required=True)
    s_active.set_defaults(func=cmd_sizes)

    categories = sub.add_parser("categories")
    categories_sub = categories.add_subparsers(dest="action", required=True)
    categories_sub.add_parser("list").set_defaults(func=cmd_categories)
    cat_create = categories_sub.add_parser("create")
    cat_create.add_argument("--name", required=True)
    cat_create.add_argument("--sort-order", type=int, required=True)
    cat_create.set_defaults(func=cmd_categories)

    products = sub.add_parser("products")
    products_sub = products.add_subparsers(dest="action", required=True)
    products_sub.add_parser("list").set_defaults(func=cmd_products)
    p_create = products_sub.add_parser("create")
    p_create.add_argument("--code", required=True)
    p_create.add_argument("--name", required=True)
    p_create.add_argument("--description")
    p_create.add_argument(
        "--price", type=float,
        help="Precio de referencia (opcional): si se omite, el producto queda 'a cotizar' y el precio se define recién en el pedido de cada cliente",
    )
    p_create.add_argument("--category-id")
    p_create.add_argument("--featured", action="store_true")
    p_create.add_argument("--active", type=lambda v: v.lower() in ("1", "true", "yes"), default=True)
    p_create.set_defaults(func=cmd_products)
    p_update = products_sub.add_parser("update")
    p_update.add_argument("id")
    p_update.add_argument("--code")
    p_update.add_argument("--name")
    p_update.add_argument("--description")
    p_update.add_argument("--price", type=float)
    p_update.add_argument("--category-id")
    p_update.add_argument("--featured", type=lambda v: v.lower() in ("1", "true", "yes"))
    p_update.add_argument("--active", type=lambda v: v.lower() in ("1", "true", "yes"))
    p_update.set_defaults(func=cmd_products)

    images = sub.add_parser("images")
    images_sub = images.add_subparsers(dest="action", required=True)
    i_upload = images_sub.add_parser("upload")
    i_upload.add_argument("product_id")
    i_upload.add_argument("file")
    i_upload.add_argument("--sort-order", type=int, default=0)
    i_upload.add_argument("--cover", action="store_true", help="además, marca esta imagen como cover_image_path del producto")
    i_upload.set_defaults(func=cmd_images)

    variants = sub.add_parser("variants")
    variants_sub = variants.add_subparsers(dest="action", required=True)
    v_set = variants_sub.add_parser("set")
    v_set.add_argument("product_id")
    v_set.add_argument("--color-id", required=True)
    v_set.add_argument("--size-id", required=True)
    v_set.add_argument("--stock", type=int, required=True)
    v_set.add_argument("--status", default="available")
    v_set.set_defaults(func=cmd_variants)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
