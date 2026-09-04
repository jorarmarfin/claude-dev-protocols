#!/usr/bin/env python3
"""Extrae el color de marca dominante de un logo y genera variantes.

Uso:
    python3 extract_colors.py <ruta_logo.png>

Salida: JSON por stdout con:
  - brand: hex del color dominante mas "vivo" (mayor saturacion) del logo
  - candidates: lista de hasta 5 colores dominantes (hex + frecuencia)
  - light / dark: variantes del color de marca (para splash / status bar)

No requiere sklearn ni numpy — usa el quantizer MEDIANCUT de Pillow,
que ya viene con el paquete `Pillow` (import PIL).
"""
import sys
import json
import colorsys
from PIL import Image


def is_near_gray_or_extreme(r, g, b, sat_floor=0.15, light_ceiling=0.92, light_floor=0.08):
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    if s < sat_floor:
        return True
    if l > light_ceiling or l < light_floor:
        return True
    return False


def hex_of(r, g, b):
    return "#{:02X}{:02X}{:02X}".format(r, g, b)


def shift_lightness(hex_color, delta):
    r = int(hex_color[1:3], 16) / 255
    g = int(hex_color[3:5], 16) / 255
    b = int(hex_color[5:7], 16) / 255
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0.0, min(1.0, l + delta))
    r2, g2, b2 = colorsys.hls_to_rgb(h, l, s)
    return hex_of(round(r2 * 255), round(g2 * 255), round(b2 * 255))


def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "uso: extract_colors.py <logo.png>"}))
        sys.exit(1)

    path = sys.argv[1]
    img = Image.open(path).convert("RGBA")

    # Aplana pixeles transparentes fuera del conteo (el fondo del logo
    # suele ser transparente y no debe contar como "color de marca").
    pixels = [
        (r, g, b)
        for r, g, b, a in img.getdata()
        if a > 128
    ]
    if not pixels:
        print(json.dumps({"error": "el logo no tiene pixeles opacos"}))
        sys.exit(1)

    flat = Image.new("RGB", (len(pixels), 1))
    flat.putdata(pixels)

    quantized = flat.quantize(colors=16, method=Image.MEDIANCUT)
    palette = quantized.getpalette()
    color_counts = quantized.getcolors()  # [(count, palette_index), ...]
    color_counts.sort(reverse=True)

    candidates = []
    for count, idx in color_counts:
        r, g, b = palette[idx * 3: idx * 3 + 3]
        if is_near_gray_or_extreme(r, g, b):
            continue
        candidates.append({"hex": hex_of(r, g, b), "count": count})
        if len(candidates) >= 5:
            break

    if not candidates:
        # fallback: si el logo es monocromo/gris, toma el color mas frecuente sin filtrar
        count, idx = color_counts[0]
        r, g, b = palette[idx * 3: idx * 3 + 3]
        candidates = [{"hex": hex_of(r, g, b), "count": count}]

    brand = candidates[0]["hex"]

    result = {
        "brand": brand,
        "candidates": candidates,
        "light": shift_lightness(brand, 0.18),
        "dark": shift_lightness(brand, -0.18),
    }
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
