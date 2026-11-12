#!/usr/bin/env bash
# Uso: build_docx.sh manual.md [salida.docx] [referencia.docx]
# Convierte el manual en Markdown a Word con pandoc. Sin portada ni logo.
# referencia.docx (opcional) = plantilla/estilos del cliente.
set -euo pipefail
in="$1"; out="${2:-${in%.md}.docx}"; ref="${3:-}"
args=(--toc --toc-depth=2 --from markdown+pipe_tables -o "$out")
[ -n "$ref" ] && args+=(--reference-doc="$ref")
pandoc "$in" "${args[@]}"
echo "$out"
