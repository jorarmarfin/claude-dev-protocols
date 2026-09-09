# ==========================================================================
# Cabeceras de seguridad opcionales — {{PROJECT_NAME}}
# Incluir desde default.conf.template con:  include /etc/nginx/snippets/security-headers.conf;
# Ajustar CSP al sitio real antes de activar en producción.
# ==========================================================================
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
# add_header Content-Security-Policy "default-src 'self'; ..." always;
