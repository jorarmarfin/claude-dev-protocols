#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — instalación/configuración post-provisioning (WordPress)
#
#   docker compose run --rm --entrypoint bash wpcli /scripts/bootstrap.sh
#
#   1. Instala WordPress si la BD está vacía (wp core install)
#   2. Crea/actualiza el usuario admindev
#   3. Refresca los permalinks
#
# Idempotente.
# ==========================================================================
set -uo pipefail
cd /var/www/html

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn() { printf '\033[0;33m!\033[0m %s\n' "$1"; }

WP="wp --allow-root"
ADMIN_USER="${WP_ADMIN_USER:-admindev}"
ADMIN_PASS="${WP_ADMIN_PASSWORD:-admindev_local}"
ADMIN_MAIL="${WP_ADMIN_EMAIL:-admindev@local.com}"
SITE_URL="${LOCAL_SCHEME:-https}://${LOCAL_DOMAIN}"
SITE_TITLE="${WP_TITLE:-WordPress local}"

info "Verificando conexión a la base de datos…"
if ! $WP db check --quiet >/dev/null 2>&1; then
    warn "No se pudo verificar la BD."
    exit 1
fi
ok "Base de datos accesible"

if $WP core is-installed --quiet 2>/dev/null; then
    info "WordPress ya está instalado — actualizando usuario admin…"
    $WP user update "$ADMIN_USER" \
        --user_pass="$ADMIN_PASS" \
        --user_email="$ADMIN_MAIL" \
        --role=administrator >/dev/null 2>&1 \
        || $WP user create "$ADMIN_USER" "$ADMIN_MAIL" --role=administrator --user_pass="$ADMIN_PASS" >/dev/null
    ok "Usuario '$ADMIN_USER' listo"
else
    info "Instalando WordPress (BD vacía)…"
    $WP core install \
        --url="$SITE_URL" \
        --title="$SITE_TITLE" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASS" \
        --admin_email="$ADMIN_MAIL" \
        --skip-email
    ok "WordPress instalado"
fi

info "Refrescando permalinks…"
$WP rewrite structure '/%postname%/' --hard >/dev/null 2>&1 || true
$WP rewrite flush --hard >/dev/null 2>&1 || true
ok "Permalinks refrescados"

echo
ok "Bootstrap completado."
cat <<EOF

  ┌──────────────────────────────────────────────────────────────┐
  │  Sitio    : ${SITE_URL}
  │  Admin    : ${SITE_URL}/wp-admin/
  │  Usuario  : ${ADMIN_USER}
  │  Password : ${ADMIN_PASS}
  └──────────────────────────────────────────────────────────────┘

EOF
