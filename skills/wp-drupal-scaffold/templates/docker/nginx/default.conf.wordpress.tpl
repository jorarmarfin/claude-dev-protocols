# ==========================================================================
# nginx — {{PROJECT_NAME}} (WordPress)
# Plantilla procesada por envsubst al arrancar (variables ${...} del .env).
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

    root /var/www/html;
    index index.php index.html;

    ssl_certificate     /etc/nginx/certs/local-cert.pem;
    ssl_certificate_key /etc/nginx/certs/local-key.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    client_max_body_size 64M;
    charset utf-8;

    access_log /var/log/nginx/access.log;
    error_log  /var/log/nginx/error.log;

    # Descomentar cuando el sitio ya defina su política de cabeceras/CSP.
    # include /etc/nginx/snippets/security-headers.conf;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass   php:9000;
        fastcgi_index  index.php;
        include        fastcgi_params;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO       $fastcgi_path_info;
        fastcgi_read_timeout 300;
        fastcgi_param HTTPS on;
    }

    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
        return 404;
    }

    location ~* \.(jpg|jpeg|png|gif|webp|svg|ico|css|js|woff|woff2|ttf|eot|otf|pdf|zip|xml)$ {
        expires 7d;
        access_log off;
        try_files $uri =404;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; allow all; }
    location ~ /\. { deny all; access_log off; log_not_found off; }
}
