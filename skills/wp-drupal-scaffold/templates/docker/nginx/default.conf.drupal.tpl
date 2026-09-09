# ==========================================================================
# nginx — {{PROJECT_NAME}} (Drupal, clean URLs)
# Plantilla procesada por envsubst al arrancar (variables ${...} del .env).
# Basada en el vhost de referencia oficial de Drupal para nginx.
# ==========================================================================

server {
    listen 80;
    server_name ${LOCAL_DOMAIN};
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name ${LOCAL_DOMAIN};

    root /var/www/html/web;
    index index.php;

    ssl_certificate     /etc/nginx/certs/local-cert.pem;
    ssl_certificate_key /etc/nginx/certs/local-key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    client_max_body_size 64M;
    charset utf-8;

    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    # Descomentar cuando el sitio ya defina su política de cabeceras/CSP.
    # include /etc/nginx/snippets/security-headers.conf;

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { allow all; log_not_found off; access_log off; }

    # Clean URLs de Drupal.
    location / {
        try_files $uri /index.php?$query_string;
    }

    location @rewrite {
        rewrite ^ /index.php;
    }

    # No cachear los archivos generados dinámicamente (agregados CSS/JS, imágenes estilo).
    location ~ ^/sites/.*/files/styles/ { try_files $uri @rewrite; }
    location ~ ^/sites/.*/files/css/    { try_files $uri @rewrite; }
    location ~ ^/sites/.*/files/js/     { try_files $uri @rewrite; }

    location ~* \.(jpg|jpeg|png|gif|webp|svg|ico|css|js|woff|woff2|ttf|eot|otf|pdf|zip|xml)$ {
        expires 7d;
        access_log off;
        try_files $uri @rewrite;
    }

    location ~ \.php$|^/update.php {
        try_files $uri /index.php?$query_string;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass   php:9000;
        fastcgi_index  index.php;
        include        fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO       $fastcgi_path_info;
        fastcgi_read_timeout 300;
        fastcgi_param HTTPS on;
    }

    # No servir dotfiles ni directorios internos de Drupal (settings, sites.php).
    location ~ (^|/)\. { return 403; }
    location ~ ^/sites/[^/]+/settings.*\.php$ { deny all; }
}
