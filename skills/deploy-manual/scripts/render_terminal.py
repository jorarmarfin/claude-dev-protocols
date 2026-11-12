#!/usr/bin/env python3
"""Renderiza capturas de terminal Linux (PNG) desde un JSON.

Uso: render_terminal.py capturas.json [carpeta_salida]

capturas.json = lista de:
{
  "file": "01-conectar-ssh",          # sin extensión; se numera en el JSON
  "user": "deploy", "host": "srv-prod", "cwd": "~",
  "steps": [ {"cmd": "ssh deploy@10.0.0.5", "out": "Welcome to Ubuntu 24.04\\n..."} ]
}
"cwd" puede cambiarse por paso ("cwd" = prompt antes del comando; "cwd_after" = prompt final tras el último, p. ej. después de un cd). "out" es opcional.
"""
import json, sys, os
from PIL import Image, ImageDraw, ImageFont

FONTS = [
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf",
    os.path.expanduser("~/.local/share/fonts/JetBrainsMono/JetBrainsMonoNerdFontMono-Regular.ttf"),
    "/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf",
]
BG, FG = (30, 30, 30), (212, 212, 212)
GREEN, BLUE, TITLE_BG = (95, 211, 95), (110, 160, 255), (50, 50, 50)
SIZE, PAD, TITLE_H, MAXCOLS = 16, 18, 30, 110

def load_font():
    for p in FONTS:
        if os.path.exists(p):
            return ImageFont.truetype(p, SIZE)
    return ImageFont.load_default()

def wrap(line):
    return [line[i:i + MAXCOLS] for i in range(0, len(line), MAXCOLS)] or [""]

def render(spec, outdir):
    font = load_font()
    cw = font.getlength("M")
    lh = SIZE + 6
    user, host = spec.get("user", "user"), spec.get("host", "server")
    rows = []  # lista de segmentos [(texto, color)]
    for st in spec["steps"]:
        cwd = st.get("cwd", spec.get("cwd", "~"))
        prompt = [(f"{user}@{host}", GREEN), (":", FG), (cwd, BLUE), ("$ ", FG)]
        cmd_lines = wrap(st["cmd"])
        rows.append(prompt + [(cmd_lines[0], FG)])
        rows += [[(l, FG)] for l in cmd_lines[1:]]
        for out in (st.get("out") or "").split("\n") if st.get("out") else []:
            rows += [[(l, FG)] for l in wrap(out)]
    if spec.get("final_prompt", True):
        last = spec["steps"][-1]
        cwd = last.get("cwd_after", last.get("cwd", spec.get("cwd", "~")))
        rows.append([(f"{user}@{host}", GREEN), (":", FG), (cwd, BLUE), ("$ ", FG)])
    width = int(PAD * 2 + cw * min(MAXCOLS, max(60, max(sum(len(t) for t, _ in r) for r in rows))))
    height = TITLE_H + PAD * 2 + lh * len(rows)
    img = Image.new("RGB", (width, height), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, width, TITLE_H], fill=TITLE_BG)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([12 + i * 20, 9, 24 + i * 20, 21], fill=c)
    title = f"{user}@{host}: {spec.get('cwd', '~')}"
    d.text((width / 2 - font.getlength(title) / 2, 6), title, font=font, fill=(170, 170, 170))
    y = TITLE_H + PAD
    for r in rows:
        x = PAD
        for text, color in r:
            d.text((x, y), text, font=font, fill=color)
            x += cw * len(text)
        y += lh
    path = os.path.join(outdir, spec["file"] + ".png")
    img.save(path)
    return path

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    specs = json.load(open(sys.argv[1], encoding="utf-8"))
    out = sys.argv[2] if len(sys.argv) > 2 else "capturas"
    os.makedirs(out, exist_ok=True)
    for s in specs:
        print(render(s, out))
