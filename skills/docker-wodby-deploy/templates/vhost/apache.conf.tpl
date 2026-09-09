# Virtualhost de Apache en el HOST (fuera de Docker) — hace de reverse
# proxy hacia el contenedor nginx de wodby, expuesto en HTTP_PORT.
# Instalar en /etc/apache2/sites-available/{{DOMAIN}}.conf y habilitar:
#   a2enmod proxy proxy_http headers
#   a2ensite {{DOMAIN}}
#   systemctl reload apache2
# antes de correr certbot.

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

    # Requerido por certbot en modo webroot (certbot --apache lo ajusta solo)
    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory "/var/www/certbot/.well-known/acme-challenge/">
        Options None
        AllowOverride None
        Require all granted
    </Directory>
</VirtualHost>
