---
name: flask-blueprint-expert
description: Desarrollo Flask siguiendo el estándar personal del usuario — application factory, blueprints por módulo de negocio (__init__.py + routes.py), SQLAlchemy con modelos centralizados, Flask-Migrate/Alembic, Flask-Login y Flask-WTF/CSRF. Usar cuando el usuario pida crear un blueprint/módulo nuevo, un modelo, una migración, o pregunte sobre estructura, rutas, permisos o convenciones en un proyecto Flask propio (ej. pyhampi). No cubre Django ni FastAPI — solo este estilo de Flask "a mano" con blueprints explícitos.
---

# Skill: Flask Blueprint Expert

## Propósito

Desarrollar features en proyectos Flask del usuario siguiendo su
convención real (derivada de `pyhampi`: sistema de gestión de boticas en
Flask), para que cualquier módulo nuevo tenga la misma forma y no haya que
adivinar dónde va cada cosa.

Complementa a [[project-scaffold]] (que arma el esqueleto inicial) y
[[phase-implementation-checklist]] (que desglosa una fase en pasos) —
este skill es el que sabe las convenciones específicas de Flask a la hora
de escribir código real, igual que `flutter-expert` para Flutter.

## Cuándo NO usar este skill

- Django → no cubierto, convenciones distintas (apps, ORM, admin)
- FastAPI → no cubierto, convenciones distintas (routers, pydantic, async)
- Scripts sueltos / notebooks de datos sin Flask → no aplica

## Stack de referencia

- **Flask** 3.x, application factory (`create_app`)
- **Flask-SQLAlchemy** — modelos, `db.session`
- **Flask-Migrate** (Alembic) — migraciones
- **Flask-Login** — auth por sesión
- **Flask-WTF** + `CSRFProtect` — formularios y CSRF
- **Jinja2** — templates, con filtros custom registrados en la factory
- Config por entorno vía `config.py` + `FLASK_ENV` (`development`/`production`/`default`)

## Convenciones (derivadas de pyhampi)

### Application factory

Todo vive en `app/__init__.py::create_app(config_name)`:
- `config_name` sale de `os.getenv("FLASK_ENV", "default")` si no se pasa
- Extensiones se inicializan ahí (`db.init_app(app)`, `migrate.init_app(...)`,
  `login_manager.init_app(...)`, `csrf.init_app(...)`) — instancias
  compartidas en `app/extensions.py`
- **No hay auto-discovery de blueprints**: se importan y registran
  explícitamente uno por uno en `create_app`. Al agregar un blueprint
  nuevo, hay que sumarlo ahí manualmente — no lo olvides.
- Modelos se importan centralizadamente (`from . import models`) antes de
  registrar blueprints, para que Alembic los detecte
- Filtros Jinja (`@app.template_filter`), context processors
  (`@app.context_processor`) y hooks globales (`@app.before_request`)
  también van en la factory, no dispersos

### Blueprints — un módulo de negocio = una carpeta

```
app/blueprints/<modulo>/
  __init__.py     # crea el Blueprint, importa routes AL FINAL
  routes.py       # vistas/endpoints del módulo
```

`__init__.py` típico:
```python
from flask import Blueprint

<modulo>_bp = Blueprint("<modulo>", __name__, url_prefix="/<modulo>")

from . import routes  # al final, evita imports circulares
```

- Import de `routes` **siempre al final** del `__init__.py` del blueprint
  (evita el circular import con las rutas que usan `<modulo>_bp`)
- Registro en la factory: `app.register_blueprint(<modulo>_bp)`, con
  `url_prefix` si no lo trae el propio Blueprint
- Si el blueprint opera antes del login (activación, setup inicial):
  `csrf.exempt(<modulo>_bp)` explícito en la factory, comentando el porqué
- Endpoints se nombran `<modulo>.<vista>` (namespace automático de Flask)
  — úsalo para checks de permisos/skip-lists (`req.endpoint.startswith(...)`)

### Modelos

- Un archivo por entidad en `app/models/<entidad>.py`
- **Todos** se re-exportan en `app/models/__init__.py` — si el modelo
  nuevo no aparece ahí, Alembic no lo detecta y `flask db migrate` no
  generará su tabla
- Relaciones multi-tenant/multi-sucursal: el dato vive en una tabla
  aparte ligada a la sucursal (ej. `BranchStock`), no como columna
  global en la entidad principal — sigue ese patrón para cualquier dato
  que varíe por sucursal/tenant

### Migraciones

```bash
flask db migrate -m "mensaje descriptivo"
flask db upgrade
```
- Revisa siempre el archivo generado en `migrations/versions/` antes de
  aplicar — Alembic no siempre detecta bien renombres o cambios de tipo
- Nunca edites una migración ya aplicada en producción; crea una nueva

### Formularios y CSRF

- Formularios con **Flask-WTF** (`FlaskForm` + `WTForms` fields), no HTML
  a mano con validación manual
- CSRF global vía `CSRFProtect` en la factory; blueprints pre-login se
  eximen explícitamente, todo lo demás queda protegido por defecto

### Auth y permisos

- Flask-Login: `current_user`, `@login_required` en las vistas que lo
  necesiten
- Checks de rol (`current_user.is_admin`) inline en las vistas o en
  `before_request` de la factory para reglas globales (ej. forzar
  selección de sucursal, bloquear módulos según licencia/plan)
- Patrón de skip-lists por prefijo de endpoint (`_skip = ("auth.",
  "static", "license.", "setup.")`) para hooks globales que no deben
  aplicar a rutas de login/estáticos/activación

### Templates

- Jinja2, filtros custom registrados en la factory (ej. `localdt` para
  fechas con timezone) en vez de lógica de formato repetida en cada
  template
- Un `context_processor` global centraliza datos que casi toda vista
  necesita (empresa activa, sucursal activa, estado de licencia, versión)
  en vez de pasarlos manualmente en cada `render_template`

## Comportamiento al pedir un módulo/blueprint nuevo

1. Confirma el nombre del módulo y qué entidades/modelos necesita
2. Crea `app/blueprints/<modulo>/__init__.py` y `routes.py` siguiendo el
   patrón de arriba
3. Crea/edita modelo(s) en `app/models/<entidad>.py` y **verifica que
   queden importados en `app/models/__init__.py`**
4. Genera la migración (`flask db migrate -m "..."`) y **revisa el
   archivo generado** antes de sugerir `flask db upgrade`
5. Registra el blueprint en `app/__init__.py::create_app` (import +
   `register_blueprint`), incluyendo `csrf.exempt` si aplica
6. Si el módulo necesita formularios, créalos con Flask-WTF
7. Si hay reglas de permiso/licencia que deban aplicar al módulo, revisa
   los `before_request` existentes en la factory en vez de duplicar lógica
8. No hay tests ni linter configurado por defecto en este tipo de
   proyecto — si el usuario pide tests, pregunta qué framework prefiere
   (pytest es lo estándar para Flask) antes de asumir uno

## Instrucciones especiales

- **Nunca auto-descubras blueprints** — este proyecto los registra a
  mano; si agregas uno, edita `create_app` explícitamente
- **El orden de imports en `__init__.py` del blueprint importa**: `routes`
  siempre al final
- **Todo modelo nuevo debe aparecer en `app/models/__init__.py`**, sin
  excepción, o Alembic no lo verá
- **Revisa migraciones generadas a mano** antes de aplicarlas — Alembic
  se equivoca con renombres/tipos
- **CSRF por defecto activo**: solo eximir blueprints que corren antes
  del login, y siempre con un comentario explicando por qué
- Si el proyecto real difiere de esta convención (otro proyecto Flask sin
  este historial), pregunta antes de forzar este patrón
