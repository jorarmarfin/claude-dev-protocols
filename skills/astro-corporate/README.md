# astro-corporate — cómo usarlo

Skill para construir webs corporativas en Astro con tu estándar
(Astro + TS + Tailwind v4, tokens, themes, variantes reutilizables).

## Qué contiene

```
astro-corporate/
├── SKILL.md                 # instrucciones que lee Claude
├── README.md                # este archivo (para ti)
└── references/
    ├── SPEC-001-Astro-Corporate-Starter.md
    └── SPEC-002-Sistema-Diseno-Variantes-Astro.md
```

## Instalar

```bash
cp -r skills/astro-corporate ~/.claude/skills/
```

Abre una **sesión nueva** de Claude Code (los skills se cargan al inicio).
Se activa solo por la descripción, o fuerzalo con `/astro-corporate`.

## Estado actual

- Existen los specs 001 y 002. **El repo starter todavía no está creado.**
- Por eso tu primera tarea es el **Modo A** (crear el starter). Hazlo una
  sola vez; después cada web nueva es **Modo B** o **C**.
- Pendientes: SPEC 003 (content model) y SPEC 004 (backend Laravel/WP).

## Los 3 modos

| Modo | Cuándo | Resultado |
|---|---|---|
| A. Crear el starter | Una sola vez | Repo base con SPEC 001 + 002 |
| B. Web nueva desde el starter | Cada cliente/proyecto | Sitio configurado con theme, secciones y contenido |
| C. Referencia visual | Tienes una captura o URL de diseño | Reproducción por secciones, validada visualmente |

## Prompts de ejemplo

### Modo A — crear el starter (primera vez)

```
Usa el skill astro-corporate, modo A. Crea el Astro Corporate Starter en
~/proyectos/astro-corporate-starter siguiendo SPEC 001 y SPEC 002.
Empieza por SPEC 001 etapas 1 a 6, verifica build al cerrar cada etapa y
párate al terminar el SPEC 001 para que lo revise antes de seguir con el 002.
```

Variante, para ir más despacio:

```
Skill astro-corporate, modo A. Solo SPEC 001 etapa 1 (proyecto, tokens,
site.ts, navigation.ts, MainLayout, Container, Button, SectionTitle).
Muéstrame el resultado antes de la etapa 2.
```

### Modo B — web nueva desde el starter

```
Usa astro-corporate, modo B. Web para "Constructora Andes", rubro
construcción, tono sobrio y confiable, color principal azul oscuro.
Páginas: inicio, nosotros, servicios, contacto. WhatsApp 51999999999.
Primero dime la composición (theme, header, hero, etc.) y espera mi OK.
El starter está en ~/proyectos/astro-corporate-starter; crea el nuevo
proyecto en ~/proyectos/constructora-andes.
```

Cambiar de theme en un proyecto ya hecho:

```
Con astro-corporate cambia el theme del proyecto a "technology" y revisa
contraste y que nada se rompa en móvil.
```

Agregar una variante nueva:

```
Con astro-corporate necesito un hero centrado con imagen abajo.
Revisa primero si HeroCentered ya lo resuelve; solo crea algo nuevo si
hace falta.
```

### Modo C — con referencia visual

```
Usa astro-corporate, modo C. Adjunto captura de la web que me gusta
(la imagen). No la copies literal. Primero dame el mapeo a mis variantes
y el theme base. Luego implementa solo Header + Hero y levanta el dev
server para comparar antes de seguir.
```

Con URL:

```
astro-corporate modo C: toma como referencia visual https://ejemplo.com
(solo estructura y estilo, nada de su marca ni textos). Mismo proceso:
mapeo, Header + Hero, comparación, y recién ahí el resto.
```

### Preparar para backend (aún sin SPEC 004)

```
Con astro-corporate prepara esta web para consumir noticias desde
WordPress más adelante. Por ahora solo deja los datos tipados en
src/data/ y los componentes recibiendo props; no conectes nada.
```

## Flujo recomendado para tu primera prueba

1. Instala el skill y abre sesión nueva.
2. Prompt del **Modo A** (completo). Revisa el starter resultante.
3. Prueba con una web real pequeña usando el **Modo B**.
4. Si tienes un diseño de referencia, prueba el **Modo C** en otro proyecto.
5. Anota qué falla o qué te falta y lo vuelves regla en el skill o spec.

## Consejos

- Pide siempre "primero la composición / el mapeo y espera mi OK": evita que programe 20 secciones en la dirección equivocada.
- Si el agente propone un componente específico de cliente o un hex suelto, es una violación de las reglas: dile "revisa las reglas del skill".
- Mantén los specs en `references/` sincronizados con los de la raíz si los editas (el skill lee los de `references/`).
