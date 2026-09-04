# claude-dev-protocols

Repositorio de skills, agents y hooks personalizados para Claude Code.
Aquí se versionan y se les da seguimiento antes de copiarlos a
`~/.claude/skills/` (o `~/.claude/agents/`, `~/.claude/hooks/`) para
activarlos. Este repo es la fuente de verdad versionada; `~/.claude/` es
el "deploy" activo que Claude Code realmente lee.

## Estructura

- `skills/` — skills instalables (carpeta con `SKILL.md` + archivos de soporte)
- `agents/` — agentes personalizados (`.md` con frontmatter)
- `hooks/` — hooks de Claude Code (vacío por ahora)

## Cómo instalar (activar) un skill o agent

**Skills**: copiar la carpeta completa a `~/.claude/skills/<nombre>/`.
```bash
cp -r skills/<nombre> ~/.claude/skills/
```
Claude Code los detecta automáticamente por su `description` — no hace
falta invocarlos por nombre, aunque también se puede forzar con
`/  <nombre>` si el skill lo soporta como slash command.

**Agents**: copiar el archivo `.md` a `~/.claude/agents/`.
```bash
cp agents/<nombre>.md ~/.claude/agents/
```
Se invocan con la herramienta `Agent` pasando `subagent_type: "<nombre>"`,
o simplemente pidiéndole a Claude "usa el agente <nombre> para...".

Nada de esto se copia automáticamente — se hace a propósito cuando el
usuario lo pide, para poder seguir iterando aquí sin romper lo que ya
está en uso.

## Flujo de trabajo pensado (cómo encajan entre sí)

```
1. Tienes un spec de un proyecto nuevo
      │
      ▼
   spec-to-phases (skill)
   → analiza el spec, genera .claude/spec-plan.md con fases,
     entregables, estado y timeline
      │
      ▼
2. Toca armar el esqueleto del proyecto
      │
      ▼
   project-scaffold (skill)
   → estructura de carpetas para Laravel / React / Astro
     (Flutter → flutter-new-app en su lugar)
      │
      ▼
3. Si es Laravel + Filament, faltan paquetes de siempre
      │
      ▼
   laravel-composer-kit (skill)
   → instala/configura Filament, Shield, Excel, PDF, log monitor,
     ubigeo (greenter solo si se pide explícitamente)
      │
      ▼
4. Toca implementar una fase del plan
      │
      ├── quieres solo el desglose de pasos, sin ejecutar código:
      │      phase-implementation-checklist (skill)
      │      → checklist granular (React/Astro/backend genérico)
      │
      └── quieres que se implemente de punta a punta:
             phase-executor (agent)
             → lee .claude/spec-plan.md, implementa, corre tests,
               marca la fase como COMPLETADA en el plan
      │
      ▼
5. En cualquier punto puedes preguntar "¿dónde me quedé?"
      │
      ▼
   spec-to-phases (skill) lee .claude/spec-plan.md y te dice la fase
   activa, qué está hecho y el próximo paso concreto
```

Para Flutter, el flujo de código día a día usa `flutter-expert` en vez de
`phase-implementation-checklist`/`phase-executor` (que no cubren Flutter
en detalle a propósito, para no duplicar). Para Flask, `phase-executor`
usa las convenciones de `flask-blueprint-expert` si detecta ese stack.

## Estado de los skills

| Skill | Estado | Copiado a ~/.claude | Notas |
|---|---|---|---|
| `spec-to-phases` | Listo | No | Convierte spec → plan de fases, guarda estado en `.claude/spec-plan.md` del proyecto destino |
| `project-scaffold` | Listo | No | Estructura de carpetas para Laravel, React, Astro. Flutter delega a `flutter-new-app` |
| `phase-implementation-checklist` | Listo | No | Checklist granular por fase (React/Astro/backend genérico). No cubre Laravel/Flutter en detalle |
| `flask-blueprint-expert` | Listo | No | Convenciones Flask (application factory, blueprints, SQLAlchemy) derivadas del proyecto pyhampi |
| `laravel-composer-kit` | Listo | No | Instala/configura Filament, Shield, Excel, PDF, log monitor, ubigeo (greenter solo bajo pedido explícito). Basado en composer.json de SisLibun |
| `flutter-new-app` | Listo (ya en uso) | Sí (origen) | Scaffold de proyecto Flutter nuevo, con templates. Este fue copiado *desde* `~/.claude/skills/` |
| `blog-article-publisher` | Listo (ya en uso) | Sí, en `~/.codex/skills/` (Codex, no Claude) | Copiado desde Codex para tenerlo también giteado aquí |

## Estado de los agents

| Agent | Estado | Copiado a ~/.claude | Notas |
|---|---|---|---|
| `phase-executor` | Listo | No | Implementa una fase completa de `.claude/spec-plan.md`: código + tests + actualiza el plan. Recomendado lanzarlo con `isolation: worktree` |

## Pendientes / ideas abiertas

- Skill de convenciones Filament específicas (Resources, Relation
  Managers, forms/tables) — `laravel-composer-kit` solo cubre la
  instalación, no el día a día de construir un Resource
- Decidir si `SKILL-spec-to-phases.md` (raíz, doc original) se elimina
  ahora que `skills/spec-to-phases/SKILL.md` lo reemplaza
- `hooks/` sigue vacío — sin necesidad identificada todavía
