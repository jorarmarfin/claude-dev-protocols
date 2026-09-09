#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — post-provisioning (Laravel, imagen wodby/php)
#   ./scripts/bootstrap.sh
# Idempotente.
# ==========================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }

ART="docker compose exec -T php php artisan"

if [[ ! -f "${PROJECT_ROOT:-./app}/.env" ]]; then
    info "Copiando .env de Laravel desde .env.example del proyecto…"
    cp "${PROJECT_ROOT:-./app}/.env.example" "${PROJECT_ROOT:-./app}/.env" 2>/dev/null || true
fi

info "Generando APP_KEY (si falta)…"
$ART key:generate --force >/dev/null 2>&1 || true
ok "APP_KEY listo"

info "Corriendo migraciones…"
$ART migrate --force
ok "Migraciones aplicadas"

$ART config:clear >/dev/null 2>&1 || true
$ART cache:clear  >/dev/null 2>&1 || true
ok "Caché limpiada"

echo
ok "Bootstrap completado. Sitio: http://localhost:${HTTP_PORT}"
