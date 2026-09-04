---
name: phase-implementation-checklist
description: Genera un checklist granular y accionable de qué hacer, en qué orden, para implementar una fase concreta de un plan (de .claude/spec-plan.md o descrita directamente) en stacks React/Astro/frontend y backend genérico — no cubre Laravel ni Flutter, que tienen sus propios skills (flutter-expert, flutter-new-app). Usar cuando el usuario diga "checklist de la fase X", "por dónde empiezo con esto", "desglosa esta fase", o quiera pasar de "qué hay que lograr" a "qué archivo toco primero".
---

# Skill: Phase Implementation Checklist

## Propósito

Tomar una fase ya definida (objetivo + entregables de alto nivel, normalmente
sacada de `.claude/spec-plan.md` generado por [[spec-to-phases]]) y
desglosarla en una secuencia concreta de pasos técnicos: qué archivo crear
primero, qué depende de qué, en qué orden implementar sin bloquearse.

No sustituye a `flutter-expert` ni a Laravel-específico: si la fase es
sobre Flutter, dile al usuario que use `flutter-expert`. Si es sobre
Laravel, indica que este skill no cubre Laravel en detalle y ofrece un
checklist genérico de backend REST si aun así lo quiere.

## Triggers

- "checklist de la fase [N/nombre]"
- "por dónde empiezo con [feature]"
- "desglosa esta fase en pasos"
- "qué archivo toco primero"
- Justo después de cerrar [[spec-to-phases]] con una fase activa en React/Astro/backend genérico

## Alcance

**Cubre**: React (Vite/Next.js), Astro, backend genérico en Node/Express,
APIs REST en general, integración frontend-backend, testing (Jest/Vitest/
Playwright/Cypress), CI básico.

**No cubre** (redirige):
- Flutter/Dart → usa `flutter-expert` (código) o `flutter-new-app` (scaffold)
- Laravel específico → este skill puede dar un checklist backend genérico
  (rutas → validación → lógica → persistencia → respuesta) pero no
  convenciones de Eloquent/Artisan; para eso el usuario debe pedirlo aparte

## Comportamiento

### 1. Obtener el contexto de la fase

- Si existe `.claude/spec-plan.md`, léelo y localiza la fase que el
  usuario referencia (por número o nombre)
- Si no existe o el usuario describe la fase directamente en el mensaje,
  trabaja con esa descripción
- Si la fase es ambigua (objetivo poco claro, entregables vagos), pregunta
  antes de desglosar — un checklist sobre un objetivo mal entendido genera
  trabajo en la dirección equivocada

### 2. Identificar el tipo de trabajo de la fase

Clasifica la fase para elegir la plantilla de checklist:
- **Feature de UI** (pantalla/componente nuevo)
- **Endpoint/API nueva**
- **Integración** (frontend consumiendo backend, servicio externo)
- **Refactor/migración**
- **Setup/infraestructura** (si es esto, probablemente ya lo cubrió [[project-scaffold]])

### 3. GENERAR el checklist granular

Formato: pasos en orden de dependencia, cada uno con el archivo/carpeta
concreto a tocar. Ejemplo de plantilla para **Feature de UI (React/Astro)**:

```markdown
## Checklist: [Nombre de la fase]

### 1. Tipos y contratos primero
- [ ] Define los tipos/interfaces en `types/[feature].ts` (o co-locado)
- [ ] Si consume API, define el shape de la respuesta esperada

### 2. Capa de datos
- [ ] Función de fetch/mutación en `lib/api/[feature].ts` o `features/[feature]/api.ts`
- [ ] Manejo de error y loading state definido (no como afterthought)

### 3. Lógica antes que UI
- [ ] Hook(s) custom si hay estado/lógica reusable: `features/[feature]/hooks/use[X].ts`
- [ ] Estado global si aplica (contexto/store) — solo si realmente se comparte entre componentes lejanos

### 4. Componentes, de adentro hacia afuera
- [ ] Componente(s) de presentación pura primero (sin estado, reciben props)
- [ ] Componente contenedor que conecta datos + presentación
- [ ] Integración en la página/ruta

### 5. Estados de la UI (no lo dejes para el final)
- [ ] Loading
- [ ] Error
- [ ] Vacío (sin datos)
- [ ] Éxito

### 6. Tests
- [ ] Unit test de la lógica (hook o función pura)
- [ ] Test de componente (render + interacción básica)
- [ ] Si es crítico: test e2e (Playwright/Cypress) del flujo completo

### 7. Cierre
- [ ] Revisar accesibilidad básica (labels, contraste, foco de teclado)
- [ ] Actualizar `.claude/spec-plan.md`: marcar entregables de la fase
- [ ] Commit(s) sugeridos: [lista de 2-4 commits atómicos]
```

Plantilla para **Endpoint/API nueva (backend genérico)**:

```markdown
## Checklist: [Nombre de la fase]

### 1. Contrato primero
- [ ] Define request/response shape (validación de entrada, forma de salida)
- [ ] Decide status codes de éxito y error

### 2. Ruta y validación
- [ ] Registra la ruta
- [ ] Middleware de validación de input (rechaza antes de tocar lógica de negocio)
- [ ] Middleware de auth/permisos si aplica

### 3. Lógica de negocio
- [ ] Función/servicio que hace el trabajo real, separado del handler de la ruta
- [ ] Maneja casos de error de negocio explícitamente (no solo try/catch genérico)

### 4. Persistencia
- [ ] Query/mutation a la BD
- [ ] Transacción si hay múltiples writes relacionados

### 5. Respuesta
- [ ] Formatea la respuesta según el contrato del paso 1
- [ ] Errores devuelven forma consistente con el resto de la API

### 6. Tests
- [ ] Test de la lógica de negocio en aislado (sin HTTP)
- [ ] Test de integración del endpoint (request → response real)
- [ ] Edge cases: input inválido, no autorizado, recurso no existe

### 7. Cierre
- [ ] Documenta el endpoint (README/OpenAPI/comentario según lo que use el proyecto)
- [ ] Actualizar `.claude/spec-plan.md`
- [ ] Commit(s) sugeridos
```

Para **Integración** (frontend + backend, o servicio externo): combina
ambas plantillas y añade un paso explícito de "probar el flujo end-to-end
manualmente antes de dar por cerrada la fase".

Para **Refactor/migración**: antepone siempre "escribir/confirmar tests
que cubran el comportamiento actual" antes de tocar código, y cierra con
"confirmar que los tests siguen pasando sin cambios".

### 4. Adaptar, no copiar literal

La plantilla es un punto de partida. Ajusta pasos según:
- Lo que el proyecto ya tiene (no repitas setup si ya existe)
- El stack real detectado en el repo (revisa `package.json`/estructura antes de asumir)
- El tamaño real de la fase — si el checklist sale enorme, es señal de que
  la fase debería dividirse (avisa al usuario)

### 5. Al terminar cada paso

Si el usuario reporta que completó pasos, marca los checkboxes en tu
respuesta y, si hay `.claude/spec-plan.md`, sincroniza el checkbox
correspondiente ahí también (ver [[spec-to-phases]] para el formato de
actualización).

## Instrucciones especiales

- **Orden por dependencia real**, no por capas arbitrarias: tipos/contrato
  antes que implementación, lógica antes que UI, todo antes que tests
  end-to-end.
- **Un paso = una acción verificable**, no "implementar todo el backend"
- **Nunca dejes los estados de error/loading/vacío para "después"** —
  inclúyelos como paso explícito, es la fuente más común de fases que se
  dan por terminadas pero no lo están
- **Si la fase es Flutter o Laravel puro**, dilo explícitamente y redirige
  en vez de dar un checklist genérico flojo
- **Sé específico con paths**: usa la estructura real del proyecto (de
  [[project-scaffold]] si se usó, o la que ya exista)
