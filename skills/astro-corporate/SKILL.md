---
name: astro-corporate
description: Construye sitios web corporativos con Astro usando el estándar personal del usuario — Astro + TypeScript + Tailwind v4, design tokens, themes (corporate/technology/minimal/elegant), variantes de secciones reutilizables y contenido separado en src/data. Usar cuando el usuario pida "crear el starter de astro", "nueva web en astro", "web corporativa", "landing en astro", "cambia el theme", "agrega una sección/variante", o comparta una captura/referencia visual para reproducir en Astro. También para preparar un sitio Astro que luego se integre con Laravel o WordPress. No cubre apps React puras ni Next.js.
---

# Skill: Astro Corporate

## Propósito

Construir webs corporativas en Astro **sin reconstruir la arquitectura cada
vez**. La fuente de verdad son dos specs, incluidos en este skill:

- `references/SPEC-001-Astro-Corporate-Starter.md` — base técnica, estructura, componentes UI, SEO, a11y, páginas.
- `references/SPEC-002-Sistema-Diseno-Variantes-Astro.md` — tokens, themes, variantes por familia, `Section`, `/design-system`.

Léelos antes de implementar o decidir algo de arquitectura. Si algo de este
SKILL.md contradice un spec, gana el spec.

## Detectar el modo de trabajo

Al activarse, decide cuál de estos tres modos aplica (pregunta solo si es
realmente ambiguo):

| Modo | Señal | Qué hacer |
|---|---|---|
| **A. Crear el starter** | No existe el repo starter; el usuario pide "crear el starter" | Implementar SPEC 001 y luego SPEC 002 por etapas |
| **B. Nueva web desde el starter** | Existe el starter; el usuario pide una web para un cliente | Clonar, configurar theme/site/contenido, componer páginas |
| **C. Referencia visual** | El usuario adjunta captura o URL de diseño | Analizar → mapear a variantes → Header+Hero → validar → seguir |

## Modo A — Crear el starter

1. Pregunta la ruta donde crear el repo si no la dio. No asumir.
2. Implementa **SPEC 001 etapas 1→6**, verificando `astro build` y `astro check` al cerrar cada etapa. No avanzar con errores pendientes.
3. Después **SPEC 002**, empezando por la cadena mínima: `HeaderSimple`, `HeroSplit`, `ServicesGrid`, `CTABanner`, `FooterCorporate` sobre el theme `corporate`. Las demás variantes solo cuando esa cadena esté estable.
4. Aplicar la regla de migración de SPEC 002 §3 (mover componentes de `sections/` a su familia, sin dejar duplicados).
5. Al terminar: `README.md` del starter con cómo clonar, cambiar theme y componer una página.

## Modo B — Nueva web desde el starter

1. Copiar el starter a la carpeta del nuevo proyecto (sin su `.git`; `git init` nuevo) o usar la plantilla del repo si está en GitHub.
2. Pedir/inferir del usuario: nombre, rubro, tono, colores/logo si los hay, páginas necesarias, contacto, si habrá backend (Laravel/WordPress).
3. Decidir y **declarar al usuario** la composición antes de programar, en este formato:
   ```
   Theme: technology
   Header: HeaderCorporate
   Hero: HeroSplit (ratio 45/55)
   Features: FeaturesIcons
   Services: ServicesGrid
   CTA: CTABanner
   Footer: FooterCorporate
   ```
4. Ajustar en este orden: `site.ts` (incluye `site.theme`) → `navigation.ts` → tokens/overrides de marca → `src/data/*` → imágenes en `src/assets/` → páginas.
5. Si hace falta algo que no existe: primero prop controlada, luego variante nueva, nunca componente específico del cliente (SPEC 002 §18).
6. Cerrar con auditoría: responsive (375/768/1024/1280/1440), a11y, SEO (title/description/canonical/OG, sitemap, 404), `astro build` limpio.

## Modo C — Referencia visual

Seguir SPEC 002 §19-20. No programar de inmediato.

1. Analizar la referencia: layout, container, header, hero, proporción texto/imagen, tipografía, colores, spacing, radios, sombras, cards, fondos, CTAs, orden de secciones.
2. Mostrar al usuario el **mapeo** referencia → variantes existentes y el theme base elegido, y qué tokens habría que ajustar.
3. Implementar **solo Header + Hero**, levantar el dev server, comparar visualmente (screenshot si hay herramienta de navegador) y corregir antes de seguir.
4. Continuar sección por sección con validación visual.
5. No copiar logotipo, marca, textos ni fotos propietarias de la referencia; usar placeholders o assets del usuario.

## Reglas duras (resumen de los specs)

1. No reconstruir la arquitectura ni crear otro proyecto Astro.
2. Reutilizar antes de crear: componente → prop → variante nueva (solo si hay diferencia estructural real).
3. Colores/radios/sombras/espaciado salen de tokens, nunca hex sueltos en componentes ni páginas.
4. Datos de empresa solo en `src/config/site.ts`; contenido en `src/data/`. Los componentes reciben todo por props y **nunca hacen `fetch`**.
5. Secciones envueltas en `ui/Section.astro` (fondo y espaciado centralizados).
6. Sin dependencias nuevas sin justificar. JS en cliente mínimo; React solo como isla para estado complejo real.
7. Responsive mobile-first, un solo H1 por página, `alt` en imágenes, foco visible, `prefers-reduced-motion`.
8. Tailwind v4: tokens en `@theme` dentro de `tokens.css`; no usar `tailwind.config` para duplicarlos.
9. Nombres de variantes genéricos (`HeroSplit`), jamás por cliente (`HeroClientA`).
10. Verificar `astro build` antes de decir que algo está terminado.

## Integración con backend (Laravel / WordPress)

Fuera de alcance de los SPEC 001-002; está previsto en SPEC 004 (aún no escrito). Mientras tanto:
- Mantener los componentes puros (solo props) para que la capa de datos se sustituya después.
- Si el usuario ya necesita conectar algo, proponer una capa `src/lib/api/` con cliente tipado y variables en `.env`, sin tocar componentes, y avisar que se saldrá del spec actual.
- Formulario de contacto: no acoplar proveedor sin pedirlo; endpoint configurable por `.env`.

## Qué NO hacer

- No implementar las 20 variantes de golpe.
- No usar Google Fonts por CDN; fuentes auto-hospedadas con `@fontsource`.
- No dejar `/design-system` accesible en producción.
- No presentar datos demo como si fueran reales.

## Skills relacionados

- `frontend-design`, `ui-ux-pro-max` — apoyo para decisiones estéticas de un theme nuevo.
- `spec-to-phases` / `phase-executor` — si el usuario quiere un plan de fases formal para el Modo A.
- `docker-wodby-deploy`, `project-scaffold` — despliegue y estructura genérica (este skill tiene prioridad para Astro corporativo).
