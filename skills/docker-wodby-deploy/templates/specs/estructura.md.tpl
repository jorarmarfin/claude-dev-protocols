# estructura.md — Referencia de directorios

**Proyecto:** {{PROJECT_NAME}} · **Última actualización:** {{DATE}}

## Leyenda

| Marca | Significado |
|---|---|
| 🟢 **git** | Versionado. Se clona con el repositorio |
| 🔵 **transferir** | No está en git y es necesario (aparte, ej. Drive/S3) |
| ⚪ **generado** | Se crea solo al desplegar. No transferir |
| 🔴 **nunca** | No versionar ni subir a producción |

## Raíz del proyecto

```
{{PROJECT_NAME}}/
│
├── 🟢 {{PROJECT_ROOT}}/         Código del proyecto (docroot)
├── 🟢 docker/                   Overrides locales opcionales (ini/vhost/config del CMS)
├── 🟢 scripts/                  setup.sh · bootstrap.sh
├── 🟢 _specs/                   tech.md · estructura.md
├── 🟢 compose.yml
├── 🟢 STEPS.md · COMMANDS.md · README.md
├── 🟢 .gitignore
├── 🟢 .env.example              Plantilla sin credenciales
│
├── ⚪ {{DB_DATA_PATH}}/         Datos de MariaDB. Borrarlo = reinstalar
├── ⚪ {{BACKUPS_PATH}}/         Dumps de BD y backups de archivos
├── ⚪ certs/                    Certificado TLS local, si LOCAL_DOMAIN está definido
├── 🔴 .env                      Credenciales locales
```

## Advertencias

- 🔴 Nunca commitear `.env` (solo `.env.example`).
- Las imágenes Wodby ya traen nginx/PHP configurados vía variables de entorno
  (`NGINX_VHOST_PRESET`, etc.) — `docker/` aquí es solo para *overrides*
  puntuales (un `php.ini` extra, un snippet de nginx, un `wp-config.local.php`
  o `settings.local.php` montado encima del real), no reemplaza la imagen.
