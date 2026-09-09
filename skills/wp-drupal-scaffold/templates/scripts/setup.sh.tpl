#!/usr/bin/env bash
# ==========================================================================
# setup.sh — prepara el entorno local antes del primer `docker compose up`
#
#   1. Crea .env desde .env.example (si no existe) con el UID/GID del host
#   2. Genera el certificado TLS local con mkcert (o autofirmado si falta)
#   3. Crea ./mysql para el volumen de datos
#
# Idempotente: se puede correr las veces que haga falta.
# ==========================================================================
set -euo pipefail

cd "$(dirname "$0")/.."

info()  { printf '\033[0;36m→\033[0m %s\n' "$1"; }
ok()    { printf '\033[0;32m✔\033[0m %s\n' "$1"; }
warn()  { printf '\033[0;33m!\033[0m %s\n' "$1"; }

# --------------------------------------------------------------------------
# 1. .env
# --------------------------------------------------------------------------
if [[ -f .env ]]; then
    ok ".env ya existe (no se toca)"
else
    info "Creando .env desde .env.example…"
    cp .env.example .env
    sed -i "s/^HOST_UID=.*/HOST_UID=$(id -u)/" .env
    sed -i "s/^HOST_GID=.*/HOST_GID=$(id -g)/" .env
    ok ".env creado (HOST_UID=$(id -u), HOST_GID=$(id -g))"
    warn "Revisa .env antes de continuar (dominio, contraseñas)."
fi

set -a; source .env; set +a
DOMAIN="${LOCAL_DOMAIN:-{{PROJECT_NAME}}.localhost}"

# --------------------------------------------------------------------------
# 2. Certificado TLS local
# --------------------------------------------------------------------------
mkdir -p certs
if [[ -f certs/local-cert.pem && -f certs/local-key.pem ]]; then
    ok "Certificado TLS ya existe en ./certs"
elif command -v mkcert >/dev/null 2>&1; then
    info "Generando certificado con mkcert para ${DOMAIN}…"
    mkcert -install >/dev/null 2>&1 || warn "No se pudo instalar la CA de mkcert (el navegador puede alertar)"
    mkcert -cert-file certs/local-cert.pem \
           -key-file  certs/local-key.pem \
           "${DOMAIN}" "*.${DOMAIN}" localhost 127.0.0.1 ::1
    ok "Certificado generado y confiado por el sistema"
else
    warn "mkcert no está instalado — generando certificado autofirmado"
    openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
        -keyout certs/local-key.pem \
        -out    certs/local-cert.pem \
        -subj   "/CN=${DOMAIN}" \
        -addext "subjectAltName=DNS:${DOMAIN},DNS:localhost,IP:127.0.0.1" \
        2>/dev/null
    ok "Certificado autofirmado generado"
fi

# --------------------------------------------------------------------------
# 3. Directorio de datos de MySQL
# --------------------------------------------------------------------------
if [[ -d mysql ]] && [[ -n "$(ls -A mysql 2>/dev/null)" ]]; then
    ok "./mysql ya tiene datos"
    info "Para reimportar/reinstalar desde cero:  docker compose down && rm -rf mysql"
else
    mkdir -p mysql
    ok "./mysql listo (vacío → instalación limpia o import de ./sql.init si existe)"
fi

echo
ok "Entorno preparado."
echo "  Siguiente paso:  docker compose up -d"
echo "  Luego:           ./scripts/bootstrap.sh"
