---
name: project-scaffold
description: Genera la estructura base de carpetas y archivos de un proyecto nuevo según su stack — Laravel, React, Astro (para Flutter usa el skill flutter-new-app, que ya cubre ese caso). Usar cuando el usuario pida "scaffold", "estructura de carpetas", "crea el proyecto base", "inicializa el proyecto", o quiera empezar un proyecto nuevo en Laravel/React/Astro siguiendo una estructura estándar y consistente entre proyectos.
---

# Skill: Project Scaffold

## Propósito

Generar la estructura inicial de un proyecto nuevo (carpetas, archivos
base, configuración) de forma consistente, para que cualquier proyecto del
usuario tenga la misma forma y nadie (ni Claude en sesiones futuras) tenga
que adivinar dónde va cada cosa.

Este skill es el paso de "andamiaje" que normalmente sigue a
[[spec-to-phases]] (Fase 1 de un plan suele ser "setup del proyecto") y
antecede a [[phase-implementation-checklist]].

## Triggers

- "scaffold", "estructura de carpetas", "crea el proyecto base"
- "inicializa el proyecto [stack]"
- "cómo organizo las carpetas de este proyecto"
- Arranque de un proyecto Laravel, React o Astro nuevo

**Excepción — Flutter**: si el stack es Flutter, no uses este skill,
invoca `flutter-new-app` — ya cubre estructura core/features, tema
Material 3, dependencias e iconos con el estándar del usuario.

## Comportamiento

### 0. Preguntas previas (si no vinieron en el mensaje)

Antes de generar nada, confirma (usa AskUserQuestion si hace falta):
- **Stack exacto y versión**: Laravel 11 / React con Vite o Next.js / Astro
- **Nombre del proyecto** (para carpeta y package name)
- **Gestor de paquetes**: composer / npm-pnpm-yarn
- **Extras conocidos de antemano**: TypeScript sí/no, Tailwind sí/no, testing framework, si va a tener backend separado (API) o es fullstack

No asumas — un scaffold equivocado en la base es más caro de corregir
después que preguntar 30 segundos ahora.

### 1. Verificar el directorio destino

`ls` la carpeta destino antes de crear nada. Si ya tiene archivos que no
sean triviales (no solo `.git`, `README.md` vacío), avisa al usuario y
confirma si continuar, en vez de sobrescribir en silencio.

### 2. Convención universal — carpeta `docs/`

Sin importar el stack, todo proyecto nuevo lleva una carpeta `docs/` en
la raíz (fuera de `src/`/`app/`) para que el usuario vaya colocando ahí
documentación pertinente (decisiones de arquitectura, notas de release,
runbooks, etc.). Créala siempre como parte del scaffold, aunque quede
vacía (`.gitkeep` si hace falta) — no generes contenido ahí a menos que
el proyecto ya tenga algo concreto que documentar (ver más abajo el caso
de colas en Laravel, que sí usa `docs/` desde el inicio).

### 3. Generar la estructura según el stack

#### Laravel

Usa el instalador oficial cuando esté disponible (`composer create-project
laravel/laravel` o `laravel new`) en vez de crear archivos a mano — es más
confiable que reconstruir el esqueleto de Laravel manualmente. Después de
eso, añade la estructura de convenciones del usuario:

```
app/
  Http/
    Controllers/Api/      # controllers de API separados de web
    Requests/              # FormRequest por acción (Store*, Update*)
    Resources/             # API Resources para respuestas JSON
    Middleware/
  Models/
  Services/                # lógica de negocio fuera de los controllers
  Repositories/            # si el proyecto lo amerita (no siempre)
database/
  migrations/
  factories/
  seeders/
routes/
  api.php
  web.php
tests/
  Feature/
  Unit/
config/
.env.example               # completo, con comentarios de qué es cada var
```

Entregables mínimos del scaffold:
- [ ] Proyecto Laravel instalado y corriendo (`php artisan serve` levanta sin error)
- [ ] `.env.example` documentado
- [ ] Carpetas `Services/`, `Http/Requests/`, `Http/Resources/` creadas (aunque vacías con un `.gitkeep` si es necesario)
- [ ] `routes/api.php` con un endpoint de healthcheck (`GET /api/health`)
- [ ] Configuración de CORS si va a servir a un frontend separado
- [ ] `README.md` con setup instructions (clonar, `.env`, migrar, correr)

##### `api.http` — obligatorio en cuanto haya API

En cuanto el proyecto tenga endpoints de API (aunque sea solo el
healthcheck inicial), crea `api.http` en la raíz del proyecto con
ejemplos de request por cada endpoint (método, URL, headers, body de
ejemplo). Formato estándar de `.http` (compatible con la extensión REST
Client / el cliente HTTP de PhpStorm/IntelliJ):

```http
### Healthcheck
GET {{baseUrl}}/api/health

### Login
POST {{baseUrl}}/api/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "secret"
}
```

Define `{{baseUrl}}` como variable al inicio del archivo o en un bloque
de variables de entorno del propio formato `.http`. Actualiza
`api.http` cada vez que se agregue o cambie un endpoint — es
documentación viva de la API, no un archivo de una sola vez.

##### Colas (Horizon + systemd) — solo si el proyecto usa colas

Si el proyecto usa colas (`QUEUE_CONNECTION` distinto de `sync`, o el
usuario confirma que las va a usar), además de configurar Horizon
normalmente (`composer require laravel/horizon`, `php artisan
horizon:install`), crea `docs/queues/` con archivos de ejemplo para
desplegarlo en el servidor:

- `docs/queues/horizon.conf.example` — ejemplo de configuración de
  Supervisor/Horizon (comando `php artisan horizon`, `autostart`,
  `autorestart`, `user`, `redirect_stderr`, ruta de log)
- `docs/queues/laravel-queue.service.example` — ejemplo de unit file de
  systemd equivalente (`ExecStart=php artisan horizon` o `queue:work`,
  `Restart=always`, `User=`, `WorkingDirectory=`)

Estos son plantillas de referencia para cuando el usuario despliegue a
un servidor real — no se activan ni instalan automáticamente, solo
quedan documentados en `docs/queues/` para copiar y ajustar en su
momento.

#### React

Pregunta si es SPA pura (Vite) o con framework (Next.js) — la estructura
difiere.

**Vite + React:**
```
src/
  components/
    ui/                    # componentes genéricos reutilizables
  features/                # organización por feature, no por tipo
    [feature]/
      components/
      hooks/
      api.ts
  hooks/                   # hooks compartidos
  lib/                     # utilidades, clients (axios/fetch wrapper)
  pages/ o routes/         # según router usado
  types/
  App.tsx
  main.tsx
tests/
  o co-locado *.test.tsx junto al componente
```

**Next.js (App Router):**
```
app/
  (routes)/
  api/
components/
  ui/
features/
  [feature]/
lib/
hooks/
types/
```

Entregables mínimos:
- [ ] Proyecto inicializado (`npm create vite` o `create-next-app`) y corre en dev
- [ ] TypeScript configurado (si se pidió)
- [ ] Estructura de carpetas de arriba creada
- [ ] Cliente HTTP base en `lib/` (axios o fetch wrapper con baseURL desde env)
- [ ] Linter + formatter configurados (ESLint, Prettier)
- [ ] `.env.example`
- [ ] `README.md` con setup instructions

#### Astro

```
src/
  components/
  layouts/
  pages/
  content/                 # si usa content collections
    config.ts
  styles/
  lib/
public/
astro.config.mjs
```

Entregables mínimos:
- [ ] Proyecto inicializado (`npm create astro@latest`) y corre en dev
- [ ] Integraciones necesarias instaladas (Tailwind, React/Vue islands, etc. — preguntar cuáles)
- [ ] Estructura de carpetas de arriba
- [ ] `content/config.ts` con schema si el proyecto usa colecciones de contenido
- [ ] `README.md` con setup instructions

### 4. Después de generar

- Corre el proyecto (`php artisan serve`, `npm run dev`, etc.) para
  confirmar que arranca sin error antes de reportar como terminado
- Inicializa git si no es un repo aún (pregunta primero)
- Resume al usuario: qué se creó, cómo correrlo, qué falta configurar
  manualmente (credenciales, servicios externos)
- Si el usuario tiene un plan de fases activo ([[spec-to-phases]],
  `.claude/spec-plan.md`), sugiere marcar la fase de setup como
  completada ahí

## Instrucciones especiales

- **No reinventes instaladores oficiales**: usa `composer create-project`,
  `npm create vite`, `create-next-app`, `npm create astro` como base
  siempre que existan, y solo añade encima la estructura de convenciones.
- **Organización por feature, no por tipo de archivo**, en frontend
  (React/Astro) cuando el proyecto crezca más allá de un puñado de
  componentes.
- **Separa lógica de negocio del controller** en Laravel (`Services/`).
- **Siempre entrega un `.env.example` completo y comentado**, nunca vacío.
- **Verifica que el proyecto corre** antes de dar el scaffold por
  terminado — un scaffold que no levanta no sirve de nada.
- **`docs/` siempre se crea**, sin importar el stack — es donde el
  usuario coloca su propia documentación después.
- **`api.http` es obligatorio en cuanto haya API en Laravel**, y se
  mantiene actualizado a medida que se agregan endpoints — no es un
  archivo de una sola vez al inicio del proyecto.
- **`docs/queues/` con ejemplos de Horizon + systemd** solo si el
  proyecto usa colas — no lo crees en proyectos sin colas.
- Para Flutter, delega siempre a `flutter-new-app`.
