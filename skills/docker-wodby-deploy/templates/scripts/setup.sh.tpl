#!/usr/bin/env bash
# ==========================================================================
# setup.sh — prepara el entorno antes del primer `docker compose up`
#
#   1. Crea .env desde .env.example (si no existe)
#   2. Crea las carpetas de datos declaradas en .env (DB_DATA_PATH, etc.)
#   3. Genera certificado TLS local con mkcert, si hay dominio local (opcional)
#
# Idempotente: se puede correr las veces que haga falta.
# ==========================================================================
set -euo pipefail
cd "$(dirname "$0")/.."

info()  { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()    { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn()  { printf '\033[0;33m!\033[0m %s\n' "$1"; }

if [[ -f .env ]]; then
    ok ".env ya existe (no se toca)"
else
    info "Creando .env desde .env.example…"
    cp .env.example .env
    ok ".env creado — revísalo antes de continuar (passwords, puertos)"
fi

set -a; source .env; set +a

info "Preparando carpetas de datos…"
mkdir -p "${PROJECT_ROOT:-./app}" "${DB_DATA_PATH:-./mariadb/db-data}" "${BACKUPS_PATH:-./backups}"
ok "Carpetas listas: ${PROJECT_ROOT:-./app}, ${DB_DATA_PATH:-./mariadb/db-data}, ${BACKUPS_PATH:-./backups}"

# --------------------------------------------------------------------------
# Certificado TLS local (solo si el proyecto define LOCAL_DOMAIN — opcional,
# el preset wodby/nginx por default sirve en HTTP plano vía HTTP_PORT)
# --------------------------------------------------------------------------
if [[ -n "${LOCAL_DOMAIN:-}" ]]; then
    mkdir -p certs
    if [[ -f certs/local-cert.pem && -f certs/local-key.pem ]]; then
        ok "Certificado TLS ya existe en ./certs"
    elif command -v mkcert >/dev/null 2>&1; then
        info "Generando certificado con mkcert para ${LOCAL_DOMAIN}…"
        mkcert -install >/dev/null 2>&1 || warn "No se pudo instalar la CA de mkcert"
        mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem \
               "${LOCAL_DOMAIN}" "*.${LOCAL_DOMAIN}" localhost 127.0.0.1 ::1
        ok "Certificado generado"
    else
        warn "mkcert no está instalado — LOCAL_DOMAIN definido pero sin TLS local"
    fi
fi

echo
ok "Entorno preparado."
echo "  Siguiente paso:  docker compose up -d"
echo "  Luego:           ./scripts/bootstrap.sh"
