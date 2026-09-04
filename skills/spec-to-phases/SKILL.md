---
name: spec-to-phases
description: Convierte un spec de proyecto en un plan de fases detallado (entregables, tests, docs, riesgos) y lo guarda en un archivo de estado dentro del proyecto (.claude/spec-plan.md) para poder retomarlo en cualquier sesión futura sabiendo qué fase quedó pendiente. Usar cuando el usuario comparta un spec, pida "plan de desarrollo", "cómo divido esto en fases", "proyecto nuevo", o pida continuar/actualizar un plan de fases ya existente ("dónde me quedé", "marca la fase X como hecha", "siguiente fase").
---

# Skill: Spec to Phased Implementation

## Propósito

Convertir un spec de proyecto en un plan de fases detallado, granular y
accionable, y persistirlo como archivo de estado en el propio proyecto
(`.claude/spec-plan.md`) para que cualquier sesión futura —de este skill o
de Claude en general— pueda leer el archivo y saber exactamente en qué fase
se quedó el desarrollo y qué sigue.

El archivo de estado es la fuente de verdad. No se guarda el plan en la
memoria global del usuario (eso es para preferencias/contexto entre
proyectos) — vive junto al código, versionado en git, para que viaje con
el repo y lo pueda leer cualquiera del equipo.

## Triggers

**Crear plan nuevo:**
- "spec", "especificación", "requisitos"
- "proyecto nuevo", "nuevo proyecto"
- "fases", "plan de desarrollo", "roadmap"
- "cómo estructuro esto en fases" / "cómo divido el desarrollo"
- "dame un plan de desarrollo"

**Retomar/actualizar plan existente:**
- "dónde me quedé", "qué fase sigue", "continúa el plan"
- "marca la fase N como completada/hecha"
- "actualiza el plan", "revisa el estado del proyecto"

## Comportamiento

### 0. Detectar si ya existe un plan

Antes de generar nada, busca `.claude/spec-plan.md` en la raíz del
proyecto actual.

- **Si existe** y el usuario pidió "continuar"/"dónde me quedé": léelo,
  reporta la fase actual (`## Estado Actual`), lo completado y lo
  pendiente, y pregunta o procede según lo que pida el usuario. No
  regeneres el plan desde cero.
- **Si existe** y el usuario trae un spec nuevo o pide regenerar: confirma
  con el usuario si quiere reemplazar el plan existente (perdería el
  historial de progreso) o si el spec nuevo es una fase adicional a
  anexar.
- **Si no existe**: continúa con los pasos 1-3 para crear uno.

### 1. ANALIZAR el spec proporcionado

Identifica y extrae:
- **Requisitos funcionales**: Features, endpoints, UI screens
- **Requisitos no-funcionales**: Performance, seguridad, escalabilidad
- **Restricciones técnicas**: Stack (Laravel, Flutter, React, Astro), BD, integraciones
- **Restricciones de negocio**: Timeline, presupuesto, prioridades
- **Actores/Users**: Quién usa qué, permisos

Si el spec es ambiguo o le faltan datos críticos (stack, usuarios, alcance),
pregunta antes de generar el plan — un plan de fases sobre supuestos
equivocados es peor que preguntar.

### 2. GENERAR plan de fases

Crea fases que sean:
- **Secuenciales y dependientes**: Cada fase depende de la anterior
- **Entregables claros**: Qué código exacto, qué DB, qué tests
- **Duración realista**: 2-5 días max por fase (si es más, divide)
- **Testeable**: Cada fase tiene tests específicos
- **Documentable**: Qué documentación genera
- **Máximo 6-7 fases** — si necesita más, es un mega-proyecto: sugiere
  dividirlo en múltiples specs/planes.

### 3. ESCRIBIR el archivo de estado del proyecto

Guarda el plan completo en `.claude/spec-plan.md` (crea el directorio
`.claude/` si no existe) usando exactamente esta estructura:

```markdown
# Plan de Fases: [Nombre Proyecto]

> Generado: [fecha]. Última actualización: [fecha].
> Este archivo es la fuente de verdad del progreso. Actualízalo al
> cerrar o avanzar cada fase.

## Información General
- **Stack**: [ej: Flutter + Laravel + PostgreSQL]
- **Usuarios**: [ej: small business owners, no tech skills]
- **Restricciones**: [ej: Must work offline, sync via HTTP]
- **Timeline estimado**: X semanas (Y días por fase)

## Estado Actual
- **Fase activa**: Fase N — [nombre]
- **Progreso**: [N de M fases completadas]
- **Bloqueadores**: [ninguno / descripción]
- **Próximo paso concreto**: [una línea accionable]

## Fase 1: [Nombre descriptivo] — [PENDIENTE|EN PROGRESO|COMPLETADA]

**Duración estimada**: X días
**Objetivo**: [1-2 líneas]
**Complejidad**: [Bajo/Medio/Alto]

### Requisitos previos
- [Qué debe estar hecho antes]

### Entregables (Definición de Done)

#### Backend (si aplica)
- [ ] Modelo/Schema
- [ ] Migration
- [ ] Controller/Route (endpoints específicos)
- [ ] Middleware (si aplica)
- [ ] Validaciones

#### Frontend (si aplica)
- [ ] Screens/Components
- [ ] Navigation
- [ ] State management
- [ ] Estilos base

#### Tests
- [ ] Unit tests
- [ ] Integration tests
- [ ] Edge cases

#### Documentación
- [ ] API docs
- [ ] Component docs
- [ ] Setup/run instructions

### Posibles obstáculos
- [Qué puede salir mal / cómo mitigarlo]

### Notas de avance
- [Se llena mientras se trabaja la fase: decisiones tomadas, cambios de alcance, fecha]

---

## Fase 2: ...

---

## Timeline Total
- Fase 1: X días
- ...
**TOTAL: ~Y semanas**

## Riesgos Identificados
1. [Riesgo] → [Mitigación]

## Historial de Cambios
- [fecha]: Plan creado con N fases.
```

Cada fase lleva su propio estado (`PENDIENTE|EN PROGRESO|COMPLETADA`) en el
título — esto es lo que permite saber de un vistazo dónde se quedó el
proyecto.

### 4. DESPUÉS DE GENERAR/ACTUALIZAR

- Confirma al usuario el path del archivo (`.claude/spec-plan.md`)
- Resume: número de fases, timeline total, fase más riesgosa
- Sugiere 3-5 commits/PRs principales por fase
- Sugiere agregar `.claude/spec-plan.md` a git (no a .gitignore) para que
  el estado viaje con el repo

## Actualizar el plan durante el desarrollo

Cuando el usuario reporte avance ("terminé la fase 2", "ya hice el login"):

1. Lee `.claude/spec-plan.md`
2. Marca los checkboxes completados de esa fase
3. Cambia el estado de la fase (`PENDIENTE` → `EN PROGRESO` → `COMPLETADA`)
4. Actualiza `## Estado Actual` (fase activa, progreso, próximo paso)
5. Agrega una línea en `## Historial de Cambios` con la fecha
6. Si la fase se completó, sugiere el siguiente paso concreto de la
   fase siguiente

No regeneres el archivo completo desde cero al actualizar — edita
puntualmente para conservar las notas de avance y el historial.

## Retomar un plan ("dónde me quedé")

1. Lee `.claude/spec-plan.md`
2. Reporta en 3-5 líneas: fase activa, qué está hecho de esa fase (según
   checkboxes), qué falta, y el próximo paso concreto de `## Estado Actual`
3. No repitas el plan completo salvo que el usuario lo pida explícitamente

## Instrucciones Especiales

- **Sé específico**: No digas "implementar feature", di "crear modelo Product, migration, 3 endpoints"
- **Stack-aware**: Diferencia si es Laravel, Flutter, React, Astro, combo
- **Granular**: Cada fase máximo 5 días. Si es más, divide
- **Siempre incluye**: Tests y documentación en cada fase
- **Considera offline**: Si el spec menciona offline, Fase 1 = setup de BD local
- **Considera auth**: Si hay usuarios, Fase 1 = auth
- **Prioriza valor**: Primero features que el usuario ve, luego infraestructura
- **El archivo de estado vive en el repo**, no en la memoria global del
  usuario — es contexto del proyecto, no del usuario

## Ejemplo de spec de entrada

```
Tengo un spec para una app de inventario offline-first en Flutter.
Stack: Flutter (mobile) + Laravel (backend) + SQLite (local).
Usuarios: small business owners, no tech skills.

Features:
1. Login (email/password)
2. CRUD productos (crear, listar, editar, eliminar)
3. Historial de movimientos (entrada/salida)
4. Reportes básicos (stock by category, movements)
5. Sync con backend cuando hay conexión

Restricciones:
- Debe funcionar 100% offline
- Cuando se conecta, sincroniza automáticamente
- UI simple, sin animaciones complejas
```

Esto genera 5 fases (Setup&Auth, CRUD Productos, Movimientos, Reportes,
Sync) escritas en `.claude/spec-plan.md` con el formato de arriba.
