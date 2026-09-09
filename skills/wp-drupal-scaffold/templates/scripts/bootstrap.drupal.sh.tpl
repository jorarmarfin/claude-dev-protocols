#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — instalación/configuración post-provisioning (Drupal)
#
#   docker compose run --rm --entrypoint bash drush /scripts/bootstrap.sh
#
#   1. Instala Drupal si la BD está vacía (drush site:install)
#   2. Crea/actualiza el usuario admindev
#   3. Limpia cachés
#
# Idempotente.
# ==========================================================================
set -uo pipefail
cd /var/www/html

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

DRUSH="vendor/bin/drush"
ADMIN_USER="${DRUPAL_ADMIN_USER:-admindev}"
ADMIN_PASS="${DRUPAL_ADMIN_PASSWORD:-admindev_local}"
ADMIN_MAIL="${DRUPAL_ADMIN_EMAIL:-admindev@local.com}"
SITE_NAME="${DRUPAL_SITE_NAME:-Drupal local}"

if [[ ! -x "$DRUSH" ]]; then
    warn "$DRUSH no existe — ¿se corrió 'composer install' en el contenedor?"
    exit 1
fi

if $DRUSH status --field=bootstrap 2>/dev/null | grep -q "Successful"; then
    info "Drupal ya está instalado — actualizando usuario admin…"
    $DRUSH user:information "$ADMIN_USER" >/dev/null 2>&1 \
        && $DRUSH user:password "$ADMIN_USER" "$ADMIN_PASS" \
        || $DRUSH user:create "$ADMIN_USER" --mail="$ADMIN_MAIL" --password="$ADMIN_PASS"
    $DRUSH user:role:add administrator "$ADMIN_USER" >/dev/null 2>&1 || true
    ok "Usuario '$ADMIN_USER' listo"
else
    info "Instalando Drupal (BD vacía)…"
    $DRUSH site:install standard \
        --site-name="$SITE_NAME" \
        --account-name="$ADMIN_USER" \
        --account-pass="$ADMIN_PASS" \
        --account-mail="$ADMIN_MAIL" \
        --existing-config=no \
        -y
    ok "Drupal instalado"
fi

info "Limpiando cachés…"
$DRUSH cache:rebuild >/dev/null 2>&1 || true
ok "Cachés limpiadas"

echo
ok "Bootstrap completado."
cat <<EOF

  ┌──────────────────────────────────────────────────────────────┐
  │  Sitio    : ${LOCAL_SCHEME:-https}://${LOCAL_DOMAIN}
  │  Admin    : ${LOCAL_SCHEME:-https}://${LOCAL_DOMAIN}/user/login
  │  Usuario  : ${ADMIN_USER}
  │  Password : ${ADMIN_PASS}
  └──────────────────────────────────────────────────────────────┘

EOF
