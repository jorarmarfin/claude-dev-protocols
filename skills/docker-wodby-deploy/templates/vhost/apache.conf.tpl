# Virtualhost de Apache en el HOST (fuera de Docker) — hace de reverse
# proxy hacia el contenedor nginx de wodby, expuesto en HTTP_PORT.
# Instalación: ver STEPS.md (ruta, paquete/servicio y comando de
# habilitación varían entre Debian/Ubuntu -apache2/a2ensite- y
# RHEL/Rocky -httpd/conf.d, sin a2ensite-). Módulos requeridos en
# ambas: proxy proxy_http headers.
# El certificado se obtiene aparte con `certbot certonly --webroot` —
# este vhost NO se toca automáticamente por ningún plugin de certbot;
# una vez emitido el certificado, agrega a mano un segundo
# <VirtualHost *:443> con SSLCertificateFile/SSLCertificateKeyFile
# apuntando a /etc/letsencrypt/live/{{DOMAIN}}/.

<VirtualHost *:80>
    ServerName {{DOMAIN}}
    ServerAlias www.{{DOMAIN}}

    ErrorLog ${APACHE_LOG_DIR}/{{DOMAIN}}-error.log
    CustomLog ${APACHE_LOG_DIR}/{{DOMAIN}}-access.log combined

    ProxyPreserveHost On
    ProxyRequests Off
    ProxyPass / http://127.0.0.1:{{HTTP_PORT}}/
    ProxyPassReverse / http://127.0.0.1:{{HTTP_PORT}}/

    RequestHeader set X-Forwarded-Proto "http"

    # Requerido por certbot en modo webroot: debe apuntar al mismo
    # directorio pasado con -w en `certbot certonly --webroot` (por
    # default {{DEPLOY_PATH}}/app).
    Alias /.well-known/acme-challenge/ {{DEPLOY_PATH}}/app/.well-known/acme-challenge/
    <Directory "{{DEPLOY_PATH}}/app/.well-known/acme-challenge/">
        Options None
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
