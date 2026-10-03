# SPEC 002 --- Sistema de Diseño y Variantes de Secciones

**Proyecto:** Astro Corporate Starter\
**Versión:** 1.0\
**Dependencia:** SPEC 001 --- Astro Corporate Starter

## 1. Objetivo

Convertir el starter técnico creado en el SPEC 001 en una **biblioteca
visual corporativa reutilizable**, capaz de construir sitios con estilos
diferentes sin rehacer la arquitectura.

Este SPEC no crea una web para un cliente concreto. Debe crear variantes
estructurales, temas y reglas visuales que después puedan combinarse.

Principios:

-   reutilización antes que duplicación;
-   composición antes que páginas rígidas;
-   design tokens antes que valores arbitrarios;
-   variantes estructurales antes que componentes específicos por
    cliente;
-   responsive y accesibilidad por defecto;
-   mínimo JavaScript;
-   compatibilidad con agentes de IA.

## 2. Regla fundamental

Este SPEC continúa el proyecto existente.

**NO** crear otro proyecto Astro, cambiar el stack, rehacer `site.ts`,
eliminar componentes funcionales ni introducir React/Vue/Svelte sin una
necesidad real.

Antes de implementar, revisar lo construido con SPEC 001 y reutilizarlo.

## 3. Arquitectura objetivo

``` text
src/
├── components/
│   ├── ui/
│   │   ├── Button.astro
│   │   ├── Container.astro
│   │   ├── SectionTitle.astro
│   │   ├── Card.astro
│   │   ├── IconBox.astro
│   │   └── Section.astro
│   ├── header/
│   │   ├── HeaderSimple.astro
│   │   └── HeaderCorporate.astro
│   ├── hero/
│   │   ├── HeroSplit.astro
│   │   ├── HeroCentered.astro
│   │   └── HeroBackground.astro
│   ├── features/
│   │   ├── FeaturesIcons.astro
│   │   └── FeaturesCards.astro
│   ├── services/
│   │   ├── ServiceCard.astro
│   │   ├── ServicesGrid.astro
│   │   └── ServicesCards.astro
│   ├── about/
│   │   ├── AboutSplit.astro
│   │   └── AboutStats.astro
│   ├── testimonials/
│   │   ├── TestimonialsGrid.astro
│   │   └── TestimonialsFeatured.astro
│   ├── cta/
│   │   ├── CTABox.astro
│   │   ├── CTABanner.astro
│   │   └── CTASplit.astro
│   ├── footer/
│   │   ├── FooterSimple.astro
│   │   └── FooterCorporate.astro
│   └── sections/
│       ├── FAQ.astro
│       └── ContactForm.astro
└── styles/
    ├── global.css
    ├── tokens.css
    └── themes/
        ├── corporate.css
        ├── technology.css
        ├── minimal.css
        └── elegant.css
```

No reorganizar destructivamente archivos existentes. Actualizar imports
cuando corresponda.

**Regla de migración desde SPEC 001:** los componentes que el SPEC 001
dejó en `components/sections/` (Header, HeroSplit, Features, Services,
About, Testimonials, CTA, Footer) se **mueven** a su carpeta de familia
(`header/`, `hero/`, etc.) y se renombran a su variante equivalente
(ej. `Header` → `HeaderCorporate`, `Hero`/`HeroSplit` → `hero/HeroSplit`).
Se actualizan todos los imports y se elimina el archivo original. No
deben quedar copias duplicadas. En `sections/` solo permanecen `FAQ` y
`ContactForm`.

Los datos demo siguen el criterio del SPEC 001: archivos por entidad en
`src/data/` (`services.ts`, `features.ts`, etc.). `src/data/demo.ts`
(ver §22) solo los reexporta para el catálogo; no define datos propios.

## 4. Design Tokens

Centralizar decisiones visuales en `src/styles/tokens.css`.

`tokens.css` contiene el bloque `@theme` de Tailwind v4 (definido en el
SPEC 001 §5) y es importado desde `global.css` después de
`@import "tailwindcss"`. Así cada token es variable CSS y utilidad de
Tailwind a la vez. No declarar tokens en otro lugar ni duplicarlos en
`tailwind.config`. Los themes (§5) sobrescriben estas variables; las
utilidades siguen funcionando porque consumen `var()`.

Definir variables semánticas para:

-   tipografía (`--font-heading`, `--font-body`);
-   colores de marca;
-   background y surfaces;
-   texto normal, muted e inverse;
-   borders;
-   ancho de container;
-   radios;
-   sombras;
-   spacing de secciones;
-   escala tipográfica.

Ejemplo:

``` css
:root {
  --color-primary: #082653;
  --color-secondary: #0bb7a5;
  --color-accent: #1478e5;
  --color-background: #ffffff;
  --color-surface: #f7f9fc;
  --color-surface-dark: #071f49;
  --color-text: #172033;
  --color-text-muted: #667085;
  --color-text-inverse: #ffffff;
  --color-border: #e5e7eb;

  --container-width: 1200px;

  --radius-sm: 8px;
  --radius-md: 16px;
  --radius-lg: 24px;
  --radius-xl: 32px;
  --radius-pill: 999px;

  --shadow-sm: 0 4px 12px rgb(0 0 0 / .05);
  --shadow-md: 0 10px 30px rgb(0 0 0 / .08);
  --shadow-lg: 0 20px 50px rgb(0 0 0 / .12);

  --section-space-sm: 64px;
  --section-space-md: 96px;
  --section-space-lg: 128px;

  --font-size-h1: clamp(2.5rem, 5vw, 4.75rem);
  --font-size-h2: clamp(2rem, 4vw, 3.5rem);
  --font-size-h3: clamp(1.4rem, 2vw, 2rem);
}
```

Evitar valores arbitrarios repetidos dentro de componentes cuando exista
un token equivalente.

## 5. Themes

Implementar cuatro presets iniciales:

### Corporate

Profesional, limpio, sobrio, radios moderados y sombras suaves.
Orientado a consultoras, B2B y servicios profesionales.

### Technology

Mayor contraste, acentos intensos, gradientes opcionales, cards
modernas, radios amplios y fondos oscuros. Orientado a software, SaaS y
startups.

### Minimal

Pocos colores, mucho espacio en blanco, bordes discretos, sombras
mínimas y composición editorial.

### Elegant

Tipografía protagonista, espacios amplios, imágenes grandes, paleta
sobria y decoración mínima.

Los themes deben modificar principalmente tokens, **no duplicar
componentes**.

**Selección del theme (decidido):** `site.theme` en `src/config/site.ts`
(`"corporate" | "technology" | "minimal" | "elegant"`, por defecto
`"corporate"`). `MainLayout.astro` lo aplica como
`<html data-theme={site.theme}>`. Cada archivo de `styles/themes/`
sobrescribe tokens bajo `[data-theme="<nombre>"]`. Cambiar de theme
equivale a cambiar una línea en `site.ts`.

**Tipografía por theme:** cada theme define `--font-heading` y
`--font-body`. Las fuentes se auto-hospedan con `@fontsource` (o
`@fontsource-variable`), máximo dos familias por theme y solo los pesos
necesarios. No usar Google Fonts por CDN.

**Contraste:** cada theme debe cumplir WCAG AA (4.5:1 texto normal, 3:1
texto grande y componentes UI) para estos pares: `text`/`background`,
`text`/`surface`, `text-muted`/`background`, `text-inverse`/`primary`,
`text-inverse`/`surface-dark`, y texto de botón/fondo de botón en cada
variante. Documentar los pares verificados en un comentario al inicio
de cada archivo de theme.

## 6. Headers

### HeaderSimple

Debe soportar logo, navegación, CTA opcional y menú móvil.

### HeaderCorporate

Debe soportar logo, navegación, CTA destacado, menú móvil y
comportamiento sticky opcional. El sticky se implementa solo con CSS
(`position: sticky`) controlado por una prop; no usar JavaScript de
scroll.

No implementar mega menú en esta versión.

## 7. Heroes

### HeroSplit

Debe soportar aproximadamente ratios 50/50, 45/55 y 55/45 sin crear tres
componentes.

Props mínimas:

``` text
eyebrow
title
highlight
description
primaryCTA
secondaryCTA
image
imageAlt
imagePosition
alignment
ratio
```

### HeroCentered

Contenido centrado, dos CTAs opcionales e imagen opcional inferior.
Adecuado para SaaS y landing pages.

### HeroBackground

Contenido sobre imagen, gradiente o fondo oscuro. Garantizar contraste.
Permitir overlays mediante opciones limitadas, no estilos arbitrarios.

## 8. Features

### FeaturesIcons

Beneficios compactos con icono, título y descripción. Debe aceptar una
cantidad variable de elementos.

### FeaturesCards

La misma función con una presentación basada en cards y reutilizando
primitivas UI.

## 9. Services

### ServicesGrid

Grid adaptable. Cada servicio puede tener:

``` ts
{
  icon?: string;
  title: string;
  description: string;
  href?: string;
}
```

Responsive aproximado: 3--4 columnas desktop, 2 tablet, 1 mobile. No
asumir exactamente cuatro servicios.

### ServicesCards

Versión más visual con icono o imagen opcional, título, descripción y
enlace.

Evitar alturas fijas frágiles.

## 10. About

### AboutSplit

Imagen + contenido, con opción `reverse`.

Props:

``` text
eyebrow
title
description
image
imageAlt
features
cta
reverse
```

### AboutStats

Presentación corporativa acompañada por cifras. Los datos del starter
deben ser claramente demostrativos y no confundirse con datos reales.

## 11. Testimonials

### TestimonialsGrid

Grid sin slider ni JavaScript innecesario.

### TestimonialsFeatured

Un testimonio principal con mayor jerarquía y testimonios secundarios
opcionales.

Estructura de datos:

``` ts
{
  quote: string;
  name: string;
  role?: string;
  company?: string;
  avatar?: string;
}
```

## 12. CTAs

Implementar:

-   `CTABox`: bloque central.
-   `CTABanner`: CTA horizontal.
-   `CTASplit`: contenido + imagen/elemento visual.

En móvil deben apilarse correctamente.

## 13. Footers

### FooterSimple

Logo, navegación, redes y copyright.

### FooterCorporate

Empresa, navegación, servicios, contacto, redes y copyright.

Los datos empresariales deben provenir de configuración; no duplicarlos
dentro de componentes.

## 14. Iconografía

Preferencia:

1.  SVG local;
2.  componentes ligeros;
3.  una sola librería de iconos si realmente aporta valor.

No mezclar varias librerías. No usar emojis como iconografía corporativa
final salvo petición explícita.

## 15. Fondos y espaciado

Las secciones deben aceptar variantes semánticas:

``` text
default
surface
dark
primary
```

No pasar hexadecimales arbitrarios desde páginas.

El ritmo vertical debe consumir tokens `section-space-*`.

Esta lógica vive en un único componente `ui/Section.astro`, que todas
las variantes de sección usan como wrapper (no reimplementar fondo ni
espaciado en cada variante). Props:

``` text
background   default | surface | dark | primary   (default: default)
spacing      sm | md | lg                         (default: md)
id           opcional, para anclas
class        opcional
```

`Section` usa `Container` internamente, ajusta el color de texto según
el fondo (`dark` y `primary` usan `text-inverse`) y renderiza un
`<section>` semántico.

## 16. Cards y microinteracciones

Mantener lenguaje común de border, radius, shadow, padding y transición.

Permitido:

-   cambio de borde;
-   cambio de sombra;
-   `translateY` pequeño;
-   cambio de color/fondo.

Evitar animaciones exageradas o permanentes.

Respetar:

``` css
@media (prefers-reduced-motion: reduce)
```

## 17. Responsive

Validar como mínimo:

``` text
375px
768px
1024px
1280px
1440px
```

No diseñar desktop para luego "arreglar" móvil.

No debe existir scroll horizontal accidental.

## 18. Regla para crear variantes

No crear nombres específicos como:

``` text
HeroBlue
HeroClientA
ServicesCompany
```

Antes de crear un componente nuevo:

1.  comprobar si uno existente resuelve el caso;
2.  comprobar si una prop controlada lo resuelve;
3.  solo si existe una diferencia estructural real, crear una nueva
    variante.

## 19. Trabajo con referencias visuales

Cuando se proporcione una captura, **no programar inmediatamente**.

Primero analizar:

-   layout;
-   container;
-   header;
-   hero;
-   proporción texto/imagen;
-   jerarquía tipográfica;
-   colores;
-   spacing;
-   radios;
-   sombras;
-   cards;
-   fondos;
-   CTAs;
-   elementos decorativos;
-   orden de secciones.

Después mapear la referencia contra la biblioteca:

``` text
Header      -> HeaderCorporate
Hero        -> HeroSplit
Beneficios  -> FeaturesIcons
Servicios   -> ServicesGrid
CTA         -> CTABanner
Footer      -> FooterCorporate
```

## 20. Procedimiento para adaptar una referencia

1.  Analizar la referencia.
2.  Elegir theme base.
3.  Ajustar design tokens.
4.  Seleccionar variantes existentes.
5.  Implementar primero Header + Hero.
6.  Comparar visualmente.
7.  Corregir proporciones, spacing y tipografía.
8.  Continuar sección por sección.

No implementar toda la página antes de la primera validación visual.

La referencia sirve para estudiar composición y lenguaje visual. No
copiar automáticamente logotipo, marca, textos, fotografías o
ilustraciones propietarias.

## 21. Reglas para agentes de IA

El agente debe:

-   preservar la arquitectura;
-   reutilizar antes de crear;
-   modificar tokens antes de dispersar CSS;
-   evitar dependencias innecesarias;
-   mantener accesibilidad y responsive;
-   no introducir frameworks JS para interacciones simples;
-   trabajar sección por sección con referencias visuales;
-   no convertir cada proyecto en un fork estructural del starter.

Ejemplo de decisión esperada:

``` text
Theme: technology
Header: HeaderCorporate
Hero: HeroSplit
Hero ratio: 45/55
Features: FeaturesIcons
Services: ServicesGrid
CTA: CTABanner
Footer: FooterCorporate
```

## 22. Catálogo visual `/design-system`

Crear una página interna que muestre:

-   colores;
-   tipografía;
-   botones;
-   cards;
-   headers;
-   heroes;
-   features;
-   services;
-   about;
-   testimonials;
-   CTAs;
-   footers.

Debe servir como catálogo para humanos y agentes.

Debe tener `noindex`, no formar parte de la navegación pública y quedar
excluido del sitemap. En builds de producción la ruta no debe
generarse: restringirla al entorno de desarrollo o a una variable de
entorno (ej. `PUBLIC_ENABLE_DESIGN_SYSTEM=true`), desactivada por
defecto en producción.

Incluir un selector para previsualizar el catálogo con cada uno de los
cuatro themes.

Los datos demo se importan desde `src/data/` (archivos por entidad).
`src/data/demo.ts` solo los reexporta, sin definir datos propios.

No mezclar datos demo con configuración real.

## 23. Performance

Mantener los objetivos del SPEC 001:

-   mínimo JavaScript;
-   imágenes optimizadas;
-   CSS razonable;
-   dependencias limitadas;
-   Astro estático cuando sea posible;
-   no cargar lógica innecesaria de variantes no utilizadas.

## 24. Etapas de implementación

**Prioridad de implementación.** Primero una cadena mínima completa y
validada: `HeaderSimple`, `HeroSplit`, `ServicesGrid`, `CTABanner` y
`FooterCorporate`, sobre el theme `corporate`. Las demás variantes se
añaden después, por familia, solo cuando la cadena mínima esté estable.
Las etapas siguientes se leen con este orden en mente.

### ETAPA 1 --- Fundamentos visuales

Consolidar tokens (`tokens.css` con `@theme`), tipografía, spacing,
shadows, radius y backgrounds. Crear `ui/Section.astro` y aplicar la
regla de migración de §3. Adaptar componentes existentes para consumir
todo esto.

### ETAPA 2 --- Themes

Implementar `corporate`, `technology`, `minimal` y `elegant`, la
selección vía `site.theme` + `data-theme` y las fuentes por theme.
Verificar los pares de contraste de §5 y el layout.

### ETAPA 3 --- Header + Hero

Implementar `HeaderSimple`, `HeaderCorporate`, `HeroSplit`,
`HeroCentered` y `HeroBackground`. Validar responsive.

### ETAPA 4 --- Features + Services

Implementar `FeaturesIcons`, `FeaturesCards`, `ServicesGrid` y
`ServicesCards`.

### ETAPA 5 --- About + Testimonials

Implementar `AboutSplit`, `AboutStats`, `TestimonialsGrid` y
`TestimonialsFeatured`.

### ETAPA 6 --- CTA + Footer

Implementar `CTABox`, `CTABanner`, `CTASplit`, `FooterSimple` y
`FooterCorporate`.

### ETAPA 7 --- Catálogo

Crear `/design-system` con `noindex`.

### ETAPA 8 --- Auditoría

Revisar responsive, accesibilidad, tokens, duplicación, consistencia,
performance, imports, TypeScript y build.

No dejar errores pendientes entre etapas.

## 25. Criterios de aceptación

SPEC 002 estará terminado cuando:

-   todas las variantes compilen sin errores;
-   SPEC 001 siga funcionando;
-   exista un sistema central de tokens;
-   los cuatro themes sean intercambiables cambiando solo `site.theme`;
-   los pares de contraste de §5 cumplan WCAG AA en los cuatro themes;
-   no queden componentes duplicados en `components/sections/`;
-   `/design-system` no se genere en producción;
-   todas las variantes sean responsive;
-   no exista duplicación grave de estilos;
-   no haya componentes específicos por cliente;
-   cambiar theme no requiera editar cada componente;
-   `/design-system` permita inspeccionar la biblioteca;
-   accesibilidad, SEO y performance no hayan retrocedido.

## 26. Resultado esperado

Al finalizar, una nueva web podrá definirse inicialmente así:

``` text
Theme: technology
Header: HeaderCorporate
Hero: HeroSplit
Features: FeaturesIcons
Services: ServicesGrid
About: AboutSplit
Testimonials: TestimonialsFeatured
CTA: CTABanner
Footer: FooterCorporate
```

Después se personalizarán colores, tipografía, contenido, imágenes,
spacing y detalles visuales sin reconstruir la infraestructura.

## 27. Próximo SPEC

Dejar preparada la arquitectura para:

**SPEC 003 --- Content Model & Site Configuration**

El SPEC 003 centralizará el contenido y permitirá configurar gran parte
de cada web mediante objetos TypeScript/datos estructurados.

Después queda previsto el **SPEC 004 --- Integración con Backend**
(Laravel y WordPress: capa `src/lib/api/` con adaptadores
intercambiables, webhooks de rebuild, formulario de contacto, SEO
desde Yoast/RankMath). Las variantes de este SPEC deben seguir
recibiendo datos solo por props para que SPEC 003 y 004 no las
modifiquen.

------------------------------------------------------------------------

# Instrucción final al agente

Implementa este SPEC **sobre el proyecto existente creado con SPEC
001**.

No reconstruyas el proyecto.

Trabaja por etapas y verifica el build después de cada una.

Prioriza reutilización, consistencia y simplicidad.

El objetivo no es producir muchas variantes: es producir **pocas
variantes, sólidas, bien diseñadas y reutilizables** para múltiples
sitios corporativos.
