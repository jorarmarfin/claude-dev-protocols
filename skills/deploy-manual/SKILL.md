---
name: deploy-manual
description: Genera manuales de despliegue en Word (.docx) para proyectos Linux (Django, Flask, Laravel, Drupal, WordPress, Joomla, Moodle, Node/Astro, nativo o Docker), con capturas de terminal numeradas en una carpeta aparte. Entrevista primero (nativo/Docker, servidor, ruta, entorno, dominio, nginx/apache/gunicorn). Usar cuando el usuario pida "manual de despliegue", "manual de deploy", "documenta cómo desplegar X", "guía de instalación en servidor", "capturas del despliegue" o un documento paso a paso para entregar a un cliente.
---

# deploy-manual

Genera: `manual-<proyecto>.docx` (solo contenido: sin portada, sin logo; el cliente aplica su formato) + carpeta `capturas/` con PNG numerados. **Las imágenes NO van embebidas**: el .docx lleva marcadores `[Insertar captura 03 – descripción]` y el usuario las pega.

## Flujo

1. **Entrevista** (bloques cortos, 3-4 preguntas por turno, con defaults sugeridos). Nunca pedir credenciales reales: usar placeholders `<DB_PASSWORD>`.
2. **Plan de pasos**: mostrar índice del manual y capturas previstas; esperar OK/correcciones.
3. **Generar** `manual-<proyecto>.md` + `capturas.json`.
4. **Capturas**: `python3 ~/.claude/skills/deploy-manual/scripts/render_terminal.py capturas.json capturas/`
5. **Word**: `~/.claude/skills/deploy-manual/scripts/build_docx.sh manual-<proyecto>.md` (3er arg opcional: `.docx` de referencia si el cliente da plantilla).
6. Entregar rutas y listar capturas con su paso. Avisar que la salida de las capturas es ilustrativa si fue simulada.

Carpeta de salida: la del proyecto (preguntar si no es obvia), p. ej. `docs/deploy/`.

## Entrevista

**Base (siempre):** nombre del software/proyecto y versión · nativo o Docker · entorno (desarrollo/staging/producción) · SO del servidor (default Ubuntu 24.04) · IP/hostname (placeholder si no lo da) · usuario de despliegue · ruta de despliegue · dominio (o ninguno) · SSL (certbot sí/no) · origen del código (git URL / zip) · base de datos y motor.

**Nativo — según stack** (ver `references/stacks.md`):
- PHP (WordPress, Drupal, Laravel, Joomla, Moodle): nginx o apache · versión PHP + php-fpm · MySQL/MariaDB/Postgres.
- Python (Django, Flask): gunicorn o uwsgi · systemd · nginx como proxy · venv · versión Python.
- Node/Astro: PM2 o systemd · nginx proxy, o estático.

**Docker:**
- Stacks Wodby (Drupal, Laravel, WordPress, Moodle, Joomla): reutilizar el skill `docker-wodby-deploy` para compose.yml/.env/vhost/certbot y documentarlo.
- Otros: Dockerfile + compose; proxy inverso en el host (nginx/apache), certbot.
- Estructura estándar del usuario: carpeta raíz con compose.yml + carpeta proyecto + carpeta de datos de DB, todo relativo.

**Extras opcionales:** CI/CD, backups, cron/queues/supervisor, firewall (ufw), hardening básico, rollback.

## Estructura del manual (Markdown → Word)

1. Objetivo y alcance · 2. Datos del entorno (tabla: servidor, ruta, dominio, entorno, versiones) · 3. Prerrequisitos · 4. Pasos numerados (cada uno: qué hace, comandos en bloque de código, resultado esperado, marcador de captura) · 5. Configuración del servidor web/proxy · 6. SSL · 7. Verificación (checklist) · 8. Rollback · 9. Troubleshooting (síntoma → causa → solución) · 10. Anexos (archivos de config completos).

Reglas: comandos copiables y en orden real de ejecución; un comando por bloque lógico; indicar siempre usuario (`sudo` o no); rutas absolutas; placeholders en `<MAYÚSCULAS>`; permisos correctos del stack (`www-data`, `storage/`, `sites/default/files`…).

Marcador de captura en el .md, en su propia línea:
`> **[Insertar captura 03 – Clonado del repositorio]**`

## capturas.json

Una entrada por captura, numeradas en el nombre (`01-…`, `02-…`) y en el mismo orden que los marcadores. Formato en la cabecera de `scripts/render_terminal.py`. Ejemplo:

```json
[{"file":"03-clonar-repo","user":"deploy","host":"srv-prod","cwd":"/var/www",
  "steps":[{"cmd":"git clone git@github.com:org/app.git","out":"Cloning into 'app'...\nremote: Enumerating objects: 412, done.\nReceiving objects: 100% (412/412), done."}]}]
```

Prompt = `usuario@host:cwd$`. Usar el usuario/host/ruta reales de la entrevista.

## Capturas reales (opcional, nativo o Docker)

Si el usuario pide fidelidad: levantar contenedor lab (`docker run --rm -it ubuntu:24.04`), ejecutar los comandos y volcar la salida real en `capturas.json`. En despliegue nativo el contenedor es solo laboratorio, no forma parte del manual. Si hay Docker como método de despliegue, correr el compose real. Nunca ejecutar nada contra servidores del cliente sin que lo pida.

## Calidad

- Salida simulada debe ser plausible y coherente con versiones del manual.
- Revisar que el número de marcadores = número de PNG.
- Sin secretos reales en ningún archivo.
