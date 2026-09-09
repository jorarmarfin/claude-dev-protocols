# Virtualhost de NGINX en el HOST (fuera de Docker) — hace de reverse
# proxy hacia el contenedor nginx de wodby, expuesto en HTTP_PORT.
# Instalación: ver STEPS.md (ruta y comandos varían entre Debian/Ubuntu
# y RHEL/Rocky). El certificado se obtiene aparte con
# `certbot certonly --webroot` — este vhost NO se toca automáticamente
# por ningún plugin de certbot; una vez emitido el certificado, agrega
# a mano el bloque `listen 443 ssl` con `ssl_certificate`/
# `ssl_certificate_key` apuntando a
# /etc/letsencrypt/live/{{DOMAIN}}/fullchain.pem y privkey.pem.

server {
    listen 80;
    listen [::]:80;
    server_name {{DOMAIN}} www.{{DOMAIN}};

    access_log /var/log/nginx/{{DOMAIN}}.access.log;
    error_log  /var/log/nginx/{{DOMAIN}}.error.log;

    # Requerido por certbot en modo webroot: debe apuntar al mismo
    # directorio pasado con -w en el comando `certbot certonly --webroot`
    # (por default {{DEPLOY_PATH}}/app).
    location /.well-known/acme-challenge/ {
        root {{DEPLOY_PATH}}/app;
    }

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:{{HTTP_PORT}};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
    }
}
