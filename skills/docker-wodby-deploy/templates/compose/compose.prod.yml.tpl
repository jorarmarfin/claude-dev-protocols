# Override de producción — usar junto al compose.yml base:
#   docker compose -f compose.yml -f compose.prod.yml up -d
#
# En dev/staging (solo compose.yml) los puertos publicados escuchan en
# todas las interfaces (0.0.0.0), así que el sitio es accesible desde
# cualquier IP que llegue al host en ese puerto — útil para probar desde
# otra máquina de la red sin depender de un dominio.
#
# En producción (con este override) hay un virtualhost del servidor
# (nginx/apache, ver templates/vhost/) haciendo de reverse proxy con
# certbot delante — el puerto del contenedor ya no debe quedar abierto
# a cualquier IP, solo el propio servidor debe poder alcanzarlo. Este
# override amarra cada puerto publicado a 127.0.0.1 para lograr eso.
services:
  nginx:
    ports:
      - "127.0.0.1:${HTTP_PORT}:8080"

  adminer:
    ports:
      - "127.0.0.1:${ADMINER_PORT}:9000"
