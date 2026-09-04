# flutter-new-app

Skill para crear proyectos Flutter nuevos con la estructura estandar del
usuario, tema derivado automaticamente del logo, y las dependencias que
mas usa (Riverpod, go_router, loading_animation_widget, etc.).

**Todo el flujo esta documentado en [`SKILL.md`](./SKILL.md).** Ese es el
archivo que Claude sigue paso a paso — empieza ahi, no aqui.

## Instalacion

Este skill vive como una carpeta dentro de `~/.claude/skills/`. Para
instalarlo en otra maquina o compartirlo con alguien mas:

```bash
git clone <url-de-este-repo> ~/.claude/skills/flutter-new-app
```

Si ya tienes la carpeta `~/.claude/skills/` con otros skills, clona dentro
de ella (no reemplaces la carpeta completa). Claude Code detecta el skill
automaticamente en la siguiente sesion — no hace falta reiniciar nada mas
que abrir Claude Code de nuevo.

Para actualizarlo despues:

```bash
cd ~/.claude/skills/flutter-new-app && git pull
```

## Como usarlo

Con el logo del proyecto nuevo puesto en la raiz de `flutter_apps/`, pide:

> "crea la estructura de mi nueva app flutter, se llama X y hace Y"

Claude va a preguntar el tipo de app, la animacion de carga, y un par de
cosas mas antes de generar todo.

## Contenido de esta carpeta

- `SKILL.md` — instrucciones paso a paso (fuente de verdad).
- `templates/extract_colors.py` — script que saca el color de marca del logo.
- `templates/*.tpl` — plantillas de tema, build script y CLAUDE.md del proyecto.
- `templates/pubspec_deps.md` — catalogo de dependencias por tipo de app.

## Como se mejora

Este skill no es estatico: se actualiza cada vez que el usuario adopta un
paquete nuevo, cambia una preferencia de estructura, o corrige algo del
flujo. La seccion final de `SKILL.md` ("Como mejorar este skill con el
tiempo") explica exactamente que actualizar y donde. La forma mas simple
de pedirlo: "actualiza el skill de flutter-new-app para que tambien..." —
o invocar el skill `skill-creator` para cambios de flujo mas grandes.
