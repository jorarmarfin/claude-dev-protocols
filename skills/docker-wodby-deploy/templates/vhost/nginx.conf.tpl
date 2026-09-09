# Virtualhost de NGINX en el HOST (fuera de Docker) — hace de reverse
# proxy hacia el contenedor nginx de wodby, expuesto en HTTP_PORT.
# Instalar en /etc/nginx/sites-available/{{DOMAIN}}.conf y enlazar en
# sites-enabled antes de correr certbot.

server {
    listen 80;
    listen [::]:80;
    server_name {{DOMAIN}} www.{{DOMAIN}};

    access_log /var/log/nginx/{{DOMAIN}}.access.log;
    error_log  /var/log/nginx/{{DOMAIN}}.error.log;

    # Requerido por certbot (validación webroot); certbot --nginx lo
    # ajusta solo, pero se deja el bloque por si se usa el modo webroot.
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
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
