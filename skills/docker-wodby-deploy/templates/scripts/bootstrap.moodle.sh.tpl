#!/usr/bin/env bash
# ==========================================================================
# bootstrap.sh — post-provisioning (Moodle, imagen wodby/php genérica)
#   ./scripts/bootstrap.sh
# Idempotente.
# ==========================================================================
set -uo pipefail
cd "$(dirname "$0")/.."
set -a; source .env; set +a

info() { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()   { printf '\033[0;32m✔\033[0m %s\n' "$1"; }

CLI="docker compose exec -T php php admin/cli"
ADMIN_USER="${MOODLE_ADMIN_USER:-admindev}"
ADMIN_PASS="${MOODLE_ADMIN_PASSWORD:-Admindev_local1}"
ADMIN_MAIL="${MOODLE_ADMIN_EMAIL:-admindev@local.com}"

if docker compose exec -T php test -f config.php; then
    info "Moodle ya configurado — purgando cachés…"
    $CLI/purge_caches.php >/dev/null 2>&1 || true
    ok "Cachés purgadas"
else
    info "Instalando Moodle (install.php)…"
    $CLI/install.php --non-interactive --agree-license \
        --wwwroot="http://localhost:${HTTP_PORT}" \
        --dbtype=mariadb --dbhost=mariadb --dbname="${DB_NAME}" --dbuser="${DB_USER}" --dbpass="${DB_PASSWORD}" \
        --fullname="${PROJECT_NAME}" --shortname="${PROJECT_NAME}" \
        --adminuser="$ADMIN_USER" --adminpass="$ADMIN_PASS" --adminemail="$ADMIN_MAIL"
    ok "Moodle instalado"
fi

echo
ok "Bootstrap completado. Admin: http://localhost:${HTTP_PORT}/login (${ADMIN_USER} / ${ADMIN_PASS})"
