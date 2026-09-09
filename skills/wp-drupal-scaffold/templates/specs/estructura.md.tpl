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
├── 🟢 {{DOCROOT}}/              Document root (código del CMS)
├── 🟢 docker/                   Dockerfile, nginx, config local del CMS
├── 🟢 scripts/                  setup.sh · bootstrap.sh
├── 🟢 _specs/                   tech.md · prod.md · estructura.md
├── 🟢 tests/                    Suite de pruebas (opcional)
├── 🟢 docker-compose.yml
├── 🟢 README.md
├── 🟢 .gitignore
├── 🟢 .env.example              Plantilla sin credenciales
│
├── 🔵 sql.init/                 Dump opcional (solo si NO es instalación limpia)
│
├── ⚪ mysql/                    Datos de la base de datos. Borrarlo = reinstalar
├── ⚪ certs/                    Certificado TLS local (lo crea setup.sh)
├── 🔴 .env                      Credenciales locales
```

## Advertencias

- 🔴 Nunca commitear `.env` (solo `.env.example`).
- ⚪ `mysql/` y `certs/` son estado local — no se transfieren entre máquinas,
  se regeneran con `scripts/setup.sh` + `docker compose up`.
