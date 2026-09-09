#!/usr/bin/env bash
# Sincroniza skills/agents reales (no symlinks) de ~/.claude/ hacia este repo.
set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Sincronizando skills..."
for src in "$CLAUDE_DIR"/skills/*/; do
  name="$(basename "$src")"
  [ -L "${src%/}" ] && continue   # saltar symlinks (no son propios)
  dest="$REPO_DIR/skills/$name"
  mkdir -p "$dest"
  rsync -a --delete --exclude '.git' "$src" "$dest/"
  echo "  - $name"
done

echo "==> Sincronizando agents..."
for src in "$CLAUDE_DIR"/agents/*.md; do
  [ -e "$src" ] || continue
  name="$(basename "$src")"
  mkdir -p "$REPO_DIR/agents"
  cp "$src" "$REPO_DIR/agents/$name"
  echo "  - $name"
done

cd "$REPO_DIR"
if ! git diff --quiet || [ -n "$(git status --porcelain)" ]; then
  echo "==> Cambios detectados:"
  git status --short
else
  echo "==> Sin cambios."
fi
