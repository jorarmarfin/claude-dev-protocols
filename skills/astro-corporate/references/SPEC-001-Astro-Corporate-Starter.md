# SPEC 001 — Astro Corporate Starter

**Versión:** 1.0  
**Objetivo:** Crear un starter reutilizable para desarrollar sitios web corporativos modernos con Astro, manteniendo una arquitectura consistente y permitiendo que agentes de IA implementen nuevos diseños sin reconstruir el proyecto desde cero.

---

## 1. Visión del proyecto

Construir un **Astro Corporate Starter** que sirva como base para futuros sitios web corporativos.

Este proyecto NO debe diseñarse para una empresa específica.

Debe funcionar como una plantilla técnica reutilizable donde posteriormente sea posible cambiar:

- identidad visual
- colores
- tipografías
- logotipo
- textos
- imágenes
- servicios
- información de contacto
- orden y combinación de secciones

sin modificar la arquitectura principal.

El starter debe priorizar:

1. rendimiento
2. mantenibilidad
3. reutilización
4. responsive design
5. SEO
6. accesibilidad
7. facilidad de personalización
8. compatibilidad con agentes de IA

---

## 2. Stack tecnológico

Usar:

- Astro
- TypeScript
- Tailwind CSS v4 (tokens vía `@theme`, ver §5)
- HTML semántico
- CSS moderno cuando sea necesario

JavaScript en cliente debe utilizarse únicamente cuando exista una necesidad real de interacción.

Evitar agregar Vue, Svelte u otros frameworks. Única excepción: React, y solo como isla (`client:*`) para un componente con estado real y complejo (ej. buscador, configurador, carrito). Nunca para interacciones simples (menú móvil, acordeón, tabs simples), que se resuelven con HTML/CSS o un script mínimo.

Priorizar componentes Astro.

Integración con backend (Laravel, WordPress): fuera del alcance de V1, se define en `SPEC-004`. V1 debe dejar la arquitectura lista para ello (ver §26 y §33).

---

## 3. Principio fundamental

El starter debe separar claramente:

**estructura + contenido + diseño**

No colocar información empresarial repetida directamente dentro de múltiples componentes.

Los componentes deben obtener la información desde archivos de configuración o mediante props.

Ejemplo:

```ts
export const site = {
  name: "Empresa",
  description: "Descripción corporativa",

  contact: {
    phone: "+51 999 999 999",
    email: "contacto@empresa.com",
    whatsapp: "51999999999"
  },

  social: {
    facebook: "",
    instagram: "",
    linkedin: "",
    youtube: ""
  }
};
```

---

## 4. Arquitectura inicial

Crear como mínimo la siguiente estructura:

```text
src/
├── components/
│   ├── ui/
│   │   ├── Button.astro
│   │   ├── Container.astro
│   │   ├── SectionTitle.astro
│   │   └── Card.astro
│   │
│   ├── sections/
│   │   ├── Header.astro
│   │   ├── Hero.astro
│   │   ├── Features.astro
│   │   ├── About.astro
│   │   ├── Services.astro
│   │   ├── Testimonials.astro
│   │   ├── FAQ.astro
│   │   ├── CTA.astro
│   │   └── Footer.astro
│
├── config/
│   ├── site.ts
│   └── navigation.ts
│
├── data/                  # contenido demo, separado de los componentes
│   ├── services.ts
│   ├── features.ts
│   ├── testimonials.ts
│   └── faq.ts
│
├── layouts/
│   └── MainLayout.astro
│
├── pages/
│   ├── index.astro
│   ├── nosotros.astro
│   ├── servicios.astro
│   ├── contacto.astro
│   └── 404.astro
│
├── styles/
│   └── global.css
│
└── assets/

public/
├── favicon.svg
└── robots.txt
```

`src/data/` contiene el contenido demostrativo. Al clonar el starter para un cliente se reemplaza esta carpeta sin tocar componentes. Los componentes reciben los datos por props; las páginas son quienes importan desde `src/data/`.

La estructura puede ampliarse cuando exista una justificación técnica, pero no debe complicarse innecesariamente.

---

## 5. Design Tokens

La identidad visual debe poder modificarse desde un lugar central.

Definir tokens para:

Los tokens se declaran con la directiva `@theme` de Tailwind v4 en `src/styles/global.css`, de modo que cada token sea a la vez variable CSS y utilidad de Tailwind (ej. `bg-primary`, `text-muted`, `rounded-lg`). No duplicar valores en `tailwind.config`.

Ejemplo de la forma esperada:

```css
@import "tailwindcss";

@theme {
  --color-primary: #082653;
  --color-secondary: #0bb7a5;
  /* ... resto de tokens ... */
}
```

### Colores

```css
:root {
  --color-primary: #082653;
  --color-secondary: #0bb7a5;
  --color-accent: #1478e5;

  --color-background: #ffffff;
  --color-surface: #f7f9fc;

  --color-text: #172033;
  --color-text-muted: #667085;

  --color-border: #e5e7eb;
}
```

### Radios

```css
--radius-sm: 8px;
--radius-md: 16px;
--radius-lg: 24px;
--radius-xl: 32px;
--radius-pill: 999px;
```

### Layout

```css
--container-width: 1200px;
--section-spacing: 96px;
```

Los valores son iniciales y podrán modificarse posteriormente.

Evitar colores arbitrarios repetidos dentro de los componentes cuando exista un token equivalente.

---

## 6. Container

Crear un componente:

```text
Container.astro
```

Responsable del ancho máximo y padding horizontal consistente.

Debe comportarse aproximadamente así:

```text
desktop: max-width 1200px
tablet: padding horizontal 32px
mobile: padding horizontal 20px
```

Las secciones principales deben utilizar este componente.

---

## 7. Button

Crear un componente reutilizable:

```text
Button.astro
```

Variantes iniciales:

```text
primary
secondary
outline
ghost
```

Tamaños:

```text
sm
md
lg
```

Debe aceptar como mínimo:

```text
href
variant
size
class
```

Debe soportar enlaces internos y externos.

---

## 8. SectionTitle

Crear:

```text
SectionTitle.astro
```

Debe permitir:

```text
eyebrow
title
description
alignment
```

Ejemplo conceptual:

```text
WHAT WE DO

Our Core Services

Soluciones diseñadas para hacer crecer tu empresa.
```

Alineaciones:

```text
left
center
```

---

## 9. Header

El Header inicial debe incluir:

- logotipo
- navegación principal
- CTA
- menú responsive
- navegación móvil

La navegación NO debe estar escrita directamente dentro del componente.

Utilizar:

```text
src/config/navigation.ts
```

Ejemplo:

```ts
export const navigation = [
  { label: "Inicio", href: "/" },
  { label: "Nosotros", href: "/nosotros" },
  { label: "Servicios", href: "/servicios" },
  { label: "Contacto", href: "/contacto" }
];
```

---

## 10. Hero

Crear una primera variante:

```text
HeroSplit.astro
```

Estructura:

```text
-----------------------------------------
|                                       |
| TEXTO                  IMAGEN          |
|                                       |
| Título                                 |
| Descripción                            |
| CTA                                    |
|                                       |
-----------------------------------------
```

Debe aceptar contenido mediante props.

Debe permitir:

- eyebrow
- título
- texto destacado dentro del título
- descripción
- CTA principal
- CTA secundario opcional
- imagen
- alt de imagen

En móvil debe convertirse en una columna.

---

## 11. Features

Crear una sección reutilizable de beneficios/características.

Ejemplo:

```text
Innovación
Seguridad
Escalabilidad
Soporte
```

Los elementos deben provenir de un array y no estar codificados individualmente.

---

## 12. Services

Crear:

```text
Services.astro
```

y un componente:

```text
ServiceCard.astro
```

Cada servicio podrá tener:

```ts
{
  icon: "",
  title: "",
  description: "",
  href: ""
}
```

La cuadrícula debe adaptarse automáticamente.

Ejemplo:

```text
desktop: 4 columnas
tablet: 2 columnas
mobile: 1 columna
```

No depender estrictamente de cuatro servicios.

---

## 13. About

Crear una sección corporativa flexible con:

- título
- descripción
- imagen
- lista opcional de ventajas
- CTA opcional

Debe permitir invertir la posición:

```text
texto | imagen
```

o

```text
imagen | texto
```

---

## 14. Testimonials

Crear sistema reutilizable de testimonios.

Cada testimonio:

```ts
{
  quote: "",
  name: "",
  role: "",
  company: "",
  avatar: ""
}
```

No implementar inicialmente un slider complejo.

Priorizar una cuadrícula responsive.

---

## 15. FAQ

Crear preguntas frecuentes utilizando HTML semántico cuando sea posible.

Preferir:

```html
<details>
<summary>
```

antes que introducir JavaScript innecesario.

Las preguntas deben recibirse mediante un array.

---

## 16. CTA

Crear una sección CTA reutilizable:

```text
CTA.astro
```

Debe permitir:

- título
- descripción
- botón
- imagen opcional
- fondo configurable

Debe poder utilizarse varias veces dentro del sitio.

---

## 17. Footer

Debe obtener la información empresarial desde:

```text
site.ts
```

Debe soportar:

- logotipo
- descripción
- navegación
- servicios
- teléfono
- email
- WhatsApp
- redes sociales
- copyright dinámico

No repetir manualmente datos existentes en configuración.

---

## 18. Responsive

El proyecto debe diseñarse siguiendo un enfoque mobile-first.

Revisar como mínimo:

```text
375 px
768 px
1024 px
1280 px
1440 px
```

No debe existir scroll horizontal accidental.

Las imágenes deben mantener proporciones correctas.

Los textos no deben provocar desbordamientos.

---

## 19. Imágenes

Usar las capacidades de optimización de Astro cuando corresponda.

Las imágenes deben:

- tener `alt`
- evitar dimensiones gigantes innecesarias
- reservar espacio para reducir layout shift
- utilizar formatos modernos cuando sea conveniente

No utilizar imágenes remotas como dependencia estructural del starter.

---

## 20. SEO

`MainLayout.astro` debe permitir configurar:

```text
title
description
canonical
og:image
robots
```

Incluir como mínimo:

- title
- meta description
- canonical
- Open Graph
- Twitter/X metadata
- favicon
- viewport

Preparar la arquitectura para posteriormente añadir JSON-LD.

Incluir además:

- `@astrojs/sitemap` configurado (requiere `site` en `astro.config`, tomado de `site.ts`/variable de entorno)
- `public/robots.txt` que apunte al sitemap
- página `404.astro` con el mismo layout y un CTA de regreso al inicio

---

## 21. Accesibilidad

Como mínimo:

- HTML semántico
- jerarquía correcta H1-H6
- un solo H1 principal por página
- `alt` en imágenes
- labels en formularios
- navegación mediante teclado
- estados focus visibles
- contraste adecuado
- botones y enlaces claramente diferenciados

---

## 22. Rendimiento

Objetivo del starter:

- mínimo JavaScript posible
- evitar dependencias innecesarias
- optimizar imágenes
- evitar fuentes excesivas
- evitar animaciones pesadas
- evitar librerías completas para funcionalidades simples

Astro debe aprovecharse principalmente como generador de HTML estático.

---

## 23. Animaciones

No instalar inicialmente librerías de animación.

Utilizar CSS para:

- hover
- transiciones
- pequeños movimientos
- estados interactivos

Las animaciones complejas se evaluarán posteriormente.

Respetar:

```css
@media (prefers-reduced-motion: reduce)
```

---

## 24. Formularios

Crear la estructura visual de un formulario de contacto reutilizable.

Campos iniciales:

```text
nombre
email
teléfono
empresa
mensaje
```

No acoplar inicialmente el starter a un proveedor concreto.

Posteriormente podrá conectarse con:

- endpoint propio
- Laravel API
- servicio externo
- server actions/endpoints de Astro

---

## 25. WhatsApp

Preparar un componente opcional:

```text
WhatsAppButton.astro
```

El número debe provenir de:

```text
site.contact.whatsapp
```

No escribir el número directamente dentro del componente.

---

## 26. Contenido

Evitar llenar los componentes con contenido ficticio excesivo.

El starter debe incluir contenido demostrativo mínimo suficiente para visualizar cada componente.

El objetivo principal es construir la infraestructura reutilizable.

El contenido demo vive en `src/data/` (ver §4), nunca incrustado dentro de los componentes. Cada archivo de datos exporta un array tipado, de modo que en `SPEC-004` pueda sustituirse por una fuente remota (WordPress, Laravel) sin modificar los componentes.

---

## 27. Reglas para agentes de IA

Estas reglas son IMPORTANTES.

Cuando un agente trabaje posteriormente sobre este starter:

1. No debe reconstruir la arquitectura sin necesidad.
2. Debe reutilizar componentes existentes antes de crear nuevos.
3. No debe instalar dependencias sin justificar su necesidad.
4. No debe introducir React salvo como isla para un componente con estado real y complejo (ver §2); nunca para interacciones simples.
5. No debe colocar colores arbitrarios si existe un design token.
6. No debe duplicar información existente en `site.ts`.
7. Debe mantener responsive design.
8. Debe mantener accesibilidad.
9. Debe conservar SEO.
10. Debe trabajar sección por sección cuando se esté reproduciendo una referencia visual.

---

## 28. Trabajo con referencias visuales

Cuando se proporcione una captura de una web, NO asumir que debe copiarse literalmente.

Primero analizar:

- estructura
- proporciones
- jerarquía
- tipografía
- espaciados
- colores
- composición
- cards
- botones
- fondos
- imágenes
- elementos decorativos

Después adaptar el sistema existente.

Prioridad:

```text
1. reutilizar componente existente
2. crear variante del componente
3. crear componente nuevo
```

Nunca destruir un componente reutilizable para adaptarlo exclusivamente a una sola web.

---

## 29. Futuras variantes

La arquitectura debe permitir incorporar posteriormente:

```text
HeroSplit
HeroCentered
HeroMinimal
HeroBackground

ServicesGrid
ServicesCards
ServicesSplit

CTABox
CTABanner
CTASplit

TestimonialsGrid
TestimonialsSlider

HeaderSimple
HeaderCentered
HeaderMegaMenu

FooterSimple
FooterCorporate
FooterLarge
```

NO es necesario implementar todas estas variantes en la V1.

---

## 30. Páginas iniciales

Crear:

### Inicio

```text
Header
Hero
Features
Services
About
Testimonials
FAQ
CTA
Footer
```

### Nosotros

Página base preparada para contenido corporativo.

### Servicios

Página base preparada para listado de servicios.

### Contacto

Página con información empresarial y formulario.

### 404

Página de error con el layout principal y enlace de regreso.

---

## 31. Criterios de aceptación V1

La primera versión estará terminada cuando:

- Astro compile sin errores.
- Sitemap, `robots.txt` y página 404 funcionen.
- El contenido demo esté aislado en `src/data/`.
- TypeScript no presente errores.
- Todas las páginas funcionen.
- El sitio sea responsive.
- Header móvil funcione.
- Los componentes sean reutilizables.
- La identidad visual pueda modificarse centralmente.
- Los datos empresariales estén centralizados.
- No existan dependencias innecesarias.
- Lighthouse no muestre problemas estructurales graves.
- El starter pueda clonarse para iniciar otro proyecto sin rehacer su arquitectura.

---

## 32. Instrucción de implementación para el agente

Implementa este SPEC por etapas.

### ETAPA 1

Crear:

- proyecto Astro
- TypeScript
- Tailwind
- estructura de directorios
- `site.ts`
- `navigation.ts`
- design tokens (con `@theme` de Tailwind v4)
- `src/data/` con los archivos de contenido demo
- sitemap y `robots.txt`
- `MainLayout`
- `Container`
- `Button`
- `SectionTitle`

Verificar compilación.

### ETAPA 2

Crear:

- Header
- navegación responsive
- HeroSplit
- Features

Verificar desktop y mobile.

### ETAPA 3

Crear:

- Services
- ServiceCard
- About
- Testimonials

Verificar responsive.

### ETAPA 4

Crear:

- FAQ
- CTA
- formulario
- WhatsAppButton
- Footer

### ETAPA 5

Crear páginas:

- Inicio
- Nosotros
- Servicios
- Contacto
- 404

### ETAPA 6

Auditar:

- responsive
- accesibilidad
- SEO
- rendimiento
- duplicación de código
- consistencia visual

No avanzar dejando errores de compilación pendientes.

---

## 33. Preparación para i18n y backend (sin implementar)

V1 es monolingüe (español) y con contenido local, pero no debe cerrar el camino a:

- **i18n (ES/EN):** todo texto de interfaz (labels, botones, aria) debe vivir en config o props, no hardcodeado en componentes. Las rutas en español (`/nosotros`) se definen en `navigation.ts`. Astro i18n routing se evaluará en un spec posterior.
- **Backend (Laravel / WordPress):** los componentes nunca hacen `fetch`; reciben datos por props. Los datos salen de `src/data/` y en `SPEC-004` se reemplazarán por una capa `src/lib/api/` con adaptadores intercambiables, sin tocar componentes.

---

# Resultado esperado

Al finalizar tendremos un **starter corporativo profesional en Astro**, no una página web específica.

A partir de este starter, cada nuevo proyecto deberá poder comenzar mediante:

```bash
git clone <starter>
```

y posteriormente adaptar:

```text
configuración
design tokens
contenido
imágenes
combinación de secciones
```

sin reconstruir la infraestructura del proyecto.

Este repositorio será la base técnica común para futuros sitios corporativos.
