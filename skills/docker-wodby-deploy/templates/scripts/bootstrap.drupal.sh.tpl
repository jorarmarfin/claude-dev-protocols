#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — post-provisioning (Drupal, imagen wodby/drupal-php)
#   ./scripts/bootstrap.sh
# Idempotente.
# ==========================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

DRUSH="docker compose exec -T php vendor/bin/drush"
ADMIN_USER="${DRUPAL_ADMIN_USER:-admindev}"
ADMIN_PASS="${DRUPAL_ADMIN_PASSWORD:-admindev_local}"
ADMIN_MAIL="${DRUPAL_ADMIN_EMAIL:-admindev@local.com}"

if $DRUSH status --field=bootstrap 2>/dev/null | grep -q "Successful"; then
    info "Drupal ya instalado — actualizando usuario admin…"
    $DRUSH user:information "$ADMIN_USER" >/dev/null 2>&1 \
        && $DRUSH user:password "$ADMIN_USER" "$ADMIN_PASS" \
        || $DRUSH user:create "$ADMIN_USER" --mail="$ADMIN_MAIL" --password="$ADMIN_PASS"
    $DRUSH user:role:add administrator "$ADMIN_USER" >/dev/null 2>&1 || true
else
    info "Instalando Drupal…"
    $DRUSH site:install standard --site-name="${PROJECT_NAME}" \
        --account-name="$ADMIN_USER" --account-pass="$ADMIN_PASS" --account-mail="$ADMIN_MAIL" \
        --existing-config=no -y
fi
ok "Usuario '$ADMIN_USER' listo"

$DRUSH cache:rebuild >/dev/null 2>&1 || true
ok "Cachés limpiadas"

echo
ok "Bootstrap completado. Admin: http://localhost:${HTTP_PORT}/user/login (${ADMIN_USER} / ${ADMIN_PASS})"
