# Article Structure

This summary is based on `ESTRUCTURA_Contenido_Articulo_IA.md`. If the current project has that file, prefer the local file over this reference.

## Required JSON Fields

- `title`: required string, max 255 characters.
- `content`: required Markdown string.
- `section`: required existing section slug.

## Optional JSON Fields

- `excerpt`: short listing summary.
- `level`: `basic`, `intermediate`, or `advanced`; default is `basic`.
- `content_type`: max 60 characters; default is `article`.
- `seo_title`: max 255 characters.
- `seo_description`: free text.
- `ai_notes`: internal reviewer notes; include suggested series here.
- `topics`: existing topic slugs for draft creation/update.
- `tags`: existing tag slugs for draft creation/update.
- `sources`: structured doctrinal sources.

Do not include `series` in the JSON. The API ignores or rejects editorial fields such as `status`, `published_at`, `is_featured`, `sort_order`, `author_id`, `featured_image`, `featured_image_alt`, `review_notes`, and `slug`.

## Markdown Delivery Template

Local article files should preserve this structure:

```markdown
# [title]

## Metadatos
- excerpt: ...
- section: [slug]
- level: basic | intermediate | advanced
- content_type: article
- seo_title: ...
- seo_description: ...
- ai_notes: ...

## Serie
- ¿Pertenece a una serie?: sí/no
- Serie: [nombre] (slug: [slug] | «no existe, crear»)
- Posición sugerida: [n] de [total]

## Topics
- [slug-tema-1]
- [slug-tema-2]

## Tags
- [slug-etiqueta-1]
- [slug-etiqueta-2]

## Contenido
[Markdown completo del artículo, tal como va en content]

## Fuentes
1. source_id: [id] — reference: [ref] — quote: "[cita]" — context_note: [nota]
```

The final JSON block described in the source document is useful for manual copy/paste, but the helper script can build JSON directly from the structured Markdown sections.

## Content Rules

- Use Markdown only, never HTML.
- Use `##` and `###` inside `content`; reserve `#` for the article title.
- Keep paragraphs short.
- Register doctrinal citations in `sources`, not only inside the prose.
- Do not include signature, date, or publication metadata inside `content`.

## Sources

Each serious doctrinal article should declare structured sources in the same order as citations appear in the article:

- Existing source: `source_id`, `reference`, `quote`, and optional `context_note`.
- New source for association endpoints: `type`, `title`, and optional `reference`, `quote`, `context_note`.

Do not invent `source_id`. If source identity is ambiguous, ask the user or use the association endpoint only when they provide enough source data.

If a local article has `source_id: PENDIENTE`, do not send that source object to the draft endpoint. Mention the pending sources after the request so the editor can register or map the real source ids.
