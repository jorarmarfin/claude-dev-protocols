#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — post-provisioning (WordPress, imagen wodby/wordpress-php)
#   ./scripts/bootstrap.sh
# Idempotente.
# ==========================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

WP="docker compose exec -T php wp --allow-root"
ADMIN_USER="${WP_ADMIN_USER:-admindev}"
ADMIN_PASS="${WP_ADMIN_PASSWORD:-admindev_local}"
ADMIN_MAIL="${WP_ADMIN_EMAIL:-admindev@local.com}"

if $WP core is-installed --quiet 2>/dev/null; then
    info "WordPress ya instalado — actualizando usuario admin…"
    $WP user update "$ADMIN_USER" --user_pass="$ADMIN_PASS" --user_email="$ADMIN_MAIL" \
        >/dev/null 2>&1 || $WP user create "$ADMIN_USER" "$ADMIN_MAIL" --role=administrator --user_pass="$ADMIN_PASS" >/dev/null
else
    info "Instalando WordPress…"
    $WP core install --url="http://localhost:${HTTP_PORT}" --title="${PROJECT_NAME}" \
        --admin_user="$ADMIN_USER" --admin_password="$ADMIN_PASS" --admin_email="$ADMIN_MAIL" --skip-email
fi
ok "Usuario '$ADMIN_USER' listo"

$WP rewrite structure '/%postname%/' --hard >/dev/null 2>&1 || true
$WP rewrite flush --hard >/dev/null 2>&1 || true
ok "Permalinks refrescados"

echo
ok "Bootstrap completado. Admin: http://localhost:${HTTP_PORT}/wp-admin/ (${ADMIN_USER} / ${ADMIN_PASS})"
