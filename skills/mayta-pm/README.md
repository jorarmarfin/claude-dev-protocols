# mayta-pm

Skill que convierte ideas, conversaciones, reuniones, audios transcritos,
correos y notas desordenadas en proyectos definidos, ejecutables y
controlables: charter (`PROJECT.md`), WBS, backlog, planner Excel, actas
de reunión y reportes de estado.

**Todo el comportamiento está documentado en [`SKILL.md`](./SKILL.md).**
Ese es el archivo que Claude sigue — empieza ahí, no aquí.

## Instalación

Este skill vive como una carpeta dentro de `~/.claude/skills/`. Para
instalarlo en otra máquina o compartirlo con alguien más:

```bash
git clone <url-de-este-repo> ~/.claude/skills/mayta-pm
```

Si ya tienes la carpeta `~/.claude/skills/` con otros skills, clona dentro
de ella (no reemplaces la carpeta completa). Claude Code lo detecta
automáticamente en la siguiente sesión.

Para actualizarlo después:

```bash
cd ~/.claude/skills/mayta-pm && git pull
```

## Cómo usarlo

No hace falta invocarlo por nombre — se dispara solo cuando el mensaje
suena a gestión de proyectos. Frases que lo activan:

- **Nuevo proyecto:** "Nuevo proyecto: crear una app para..." → arranca
  captura + entrevista (problema, objetivo, alcance, tiempo, personas,
  recursos, riesgos) antes de producir tareas.
- **Analizar reunión/audio:** "Analiza esta transcripción" → extrae
  contexto, participantes, decisiones, compromisos, tareas, riesgos,
  bloqueos y posibles cambios de alcance.
- **Actualizar proyecto:** "Actualiza el proyecto con esta conversación"
  → detecta info nueva y la concilia con lo ya definido.
- **Crear tareas:** "Convierte esto en tareas" → genera WBS y backlog.
- **Crear planner:** "Crea el Excel del proyecto" → genera
  `PLAN_[NOMBRE_PROYECTO].xlsx` con dashboard, plan, Gantt, hitos,
  riesgos, decisiones, reuniones, cambios y pendientes.
- **Estado:** "¿Cómo está el proyecto?" → reporte de estado con semáforo.
- **Qué hago ahora:** "¿Qué debería hacer ahora?" → recomienda próximas
  acciones según tareas, dependencias, fechas y riesgos.

Principios que sigue siempre: no inventa datos (marca supuestos y
pendientes explícitamente), no pregunta lo que ya le diste, agrupa
preguntas en bloques pequeños priorizando alcance/tiempo/presupuesto, y
avisa con `⚠️ POSIBLE CAMBIO DE ALCANCE` cuando detecta que una solicitud
nueva se sale de lo acordado.

## Contenido de esta carpeta

- `SKILL.md` — comportamiento completo del agente (fuente de verdad):
  entrevista de proyecto, estructura de `PROJECT.md`, WBS/backlog,
  hojas del planner Excel, formato de actas y reportes, y reglas de
  detección de riesgos/cambios de alcance.

## Cómo se mejora

Este skill no es estático: se actualiza cada vez que cambie una
plantilla (ej. columnas del backlog, hojas del Excel) o una preferencia
de flujo. Pedilo directo: "actualiza el skill de mayta-pm para que
también..." — o invocá el skill `skill-creator` para cambios de flujo
más grandes.
