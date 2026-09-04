---
name: spec-to-phases-implementation
description: Convierte specs de proyecto en planes de fases detallados con entregables, dependencias y orden de implementación
triggers: ["spec", "proyecto nuevo", "fases", "plan de desarrollo", "cómo estructuro esto"]
category: project-planning
---

# Skill: Spec to Phased Implementation

## Propósito

Convertir un spec de proyecto en un plan de fases detallado, granular y actionable que el usuario pueda seguir fase por fase sin ambigüedad.

## Triggers (Cuándo se dispara)

El usuario menciona cualquiera de estos:
- "spec", "especificación", "requisitos"
- "proyecto nuevo", "nuevo proyecto"
- "fases", "plan de desarrollo", "roadmap"
- "cómo estructuro esto en fases"
- "dame un plan de desarrollo"
- "cómo divido el desarrollo"

## Comportamiento

### 1. ANALIZAR el spec proporcionado

Identifica y extrae:
- **Requisitos funcionales**: Features, endpoints, UI screens
- **Requisitos no-funcionales**: Performance, seguridad, escalabilidad
- **Restricciones técnicas**: Stack (Laravel, Flutter, React, Astro), BD, integraciones
- **Restricciones de negocio**: Timeline, presupuesto, prioridades
- **Actores/Users**: Quién usa qué, permisos

### 2. GENERAR plan de fases

Crea fases que sean:
- **Secuenciales y dependientes**: Cada fase depende de la anterior
- **Entregables claros**: Qué código exacto, qué DB, qué tests
- **Duración realista**: 2-5 días max por fase (si es más, divide)
- **Testeable**: Cada fase tiene tests específicos
- **Documentable**: Qué documentación genera

### 3. FORMATO DE OUTPUT

```markdown
# Plan de Fases: [Nombre Proyecto]

## Información General
- **Stack**: [ej: Flutter + Laravel + PostgreSQL]
- **Usuarios**: [ej: small business owners, no tech skills]
- **Restricciones**: [ej: Must work offline, sync via HTTP]
- **Timeline estimado**: X semanas (Y días por fase)

## Fase N: [Nombre descriptivo]

**Duración estimada**: X días
**Objetivo**: [1-2 líneas claras de qué se logra]
**Complejidad**: [Bajo/Medio/Alto]

### Requisitos previos
- [Qué debe estar hecho antes]

### Entregables (Definición de Done)

#### Backend (si aplica)
- [ ] Modelo/Schema (ej: `users` table con campos X, Y, Z)
- [ ] Migration (nombre específico)
- [ ] Controller/Route (endpoints específicos: GET /api/users, POST /api/users)
- [ ] Middleware (si aplica)
- [ ] Validaciones (qué valida)

#### Frontend (si aplica)
- [ ] Screens/Components (nombres específicos)
- [ ] Navigation (cómo se conectan)
- [ ] State management (si aplica)
- [ ] Estilos base

#### Tests
- [ ] Unit tests (qué casos)
- [ ] Integration tests (qué flujos)
- [ ] Edge cases (qué contempla)

#### Documentación
- [ ] API docs (si hay backend)
- [ ] Component docs (si hay frontend)
- [ ] Setup/run instructions

### Posibles obstáculos
- [Qué puede salir mal]
- [Cómo mitigarlo]

### Próximos pasos
- [Qué viene después]

---
```

### 4. DESPUÉS DE GENERAR FASES

- **Sugiere orden**: Confirma si el orden es óptimo
- **Identifica riesgos**: Qué fase es más riesgosa, por qué
- **Propone commits**: Suggiere 3-5 commits/PRs principales por fase
- **Timeline total**: Suma duración de todas las fases

---

## Ejemplos

### Entrada Ejemplo 1 (Simple)

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

### Salida Ejemplo 1

```markdown
# Plan de Fases: App de Inventario

## Información General
- **Stack**: Flutter + Laravel + SQLite
- **Usuarios**: Small business owners (no tech)
- **Restricciones**: Offline-first, auto-sync, simple UI
- **Timeline estimado**: 4-5 semanas (20-25 días)

## Fase 1: Setup & Autenticación (3 días)

**Objetivo**: Usuario puede login y tiene sesión persistente

### Entregables
- [ ] Proyecto Flutter base + estructura de carpetas
- [ ] Model: User (email, password_hash, name)
- [ ] Migration Laravel: users table
- [ ] Endpoint: POST /api/login (devuelve token JWT)
- [ ] Endpoint: POST /api/logout
- [ ] Flutter: LoginScreen + local JWT storage (Hive/Sqflite)
- [ ] Tests: Login válido, credenciales inválidas, logout

---

## Fase 2: CRUD Productos (4 días)

**Objetivo**: Usuario puede crear, listar, editar y eliminar productos localmente

### Entregables
- [ ] Model: Product (id, name, category, price, stock)
- [ ] SQLite: products table (local)
- [ ] Flutter: ProductListScreen, ProductFormScreen, ProductDetailScreen
- [ ] Local persistence: Get/Create/Update/Delete products en SQLite
- [ ] Tests: CRUD operations, validaciones (name required, stock >= 0)

---

## Fase 3: Historial de Movimientos (3 días)

**Objetivo**: Registrar cada entrada/salida de stock con fecha

### Entregables
- [ ] Model: StockMovement (product_id, type[in/out], quantity, date, notes)
- [ ] SQLite: stock_movements table
- [ ] Flutter: MovementListScreen, AddMovementScreen
- [ ] Auto-update product.stock en cada movimiento
- [ ] Tests: Movimiento válido, validar stock negativo (error)

---

## Fase 4: Reportes Básicos (3 días)

**Objetivo**: Ver reportes de stock by category y historial de movimientos

### Entregables
- [ ] Flutter: ReportsScreen
- [ ] Query: Total stock by category (suma local)
- [ ] Query: Movimientos últimos 30 días
- [ ] Export to PDF básico (plugin flutter)
- [ ] Tests: Reportes con 0 data, con data

---

## Fase 5: Sync con Backend (4 días)

**Objetivo**: Sincronizar datos a servidor cuando hay conexión

### Entregables
- [ ] Laravel: Endpoints POST /api/products/sync, POST /api/movements/sync (aceptan arrays)
- [ ] Flutter: Detector de conectividad (connectivity_plus)
- [ ] Sync logic: Al conectar, envía products y movements pendientes
- [ ] Conflict resolution: Server wins (simple)
- [ ] Offline indicator UI (badge en AppBar)
- [ ] Tests: Sync con conexión, sin conexión, datos conflictivos

---

## Timeline Total

- Fase 1: 3 días
- Fase 2: 4 días
- Fase 3: 3 días
- Fase 4: 3 días
- Fase 5: 4 días
**TOTAL: ~4.5 semanas**

## Riesgos Identificados

1. **Sync conflicts**: Qué pasa si editan en local y server? → Server wins (simple)
2. **Connectividad intermitente**: Validar sync no se queda a mitad → implementar retry logic
3. **Performance con muchos datos**: SQLite puede lentificar con 10k+ rows → index en categories
```

---

## Instrucciones Especiales para el Skill

- **Sé específico**: No digas "implementar feature", di "crear modelo Product, migration, 3 endpoints"
- **Stack-aware**: Diferencia si es Laravel, Flutter, React, Astro, combo
- **Granular**: Cada fase máximo 5 días. Si es más, divide
- **Siempre incluye**: Tests y documentación en cada fase
- **Considera offline**: Si el spec menciona offline, Fase 1 = setup de BD local
- **Considera auth**: Si hay usuarios, Fase 1 = auth
- **Prioriza valor**: Primero features que el usuario ve, luego infraestructura
- **Evita exceso**: Max 6-7 fases. Si necesita más, es un mega-proyecto

---

## Cómo Usar este Skill

### En Claude CLI:

```bash
$ claude

> [Tu spec aquí]
```

Claude reconocerá los triggers y aplicará este skill automáticamente, generando un plan de fases.

### Para Mejorar:

- Si fases muy grandes: "Divide Fase 3 en 2"
- Si orden confuso: "¿Por qué Fase 2 antes que Fase 3?"
- Si faltan detalles: "¿Qué validaciones en [Feature X]?"

---

## Evolución del Skill

Este skill es base para:
- **Skill: phase-implementation-checklist** → Checklist granular por fase
- **Skill: project-scaffold** → Genera estructura de carpetas por stack
- **Agent: phase-executor** → Ejecuta una fase completa
