---
name: blog-article-publisher
description: Send or update local Markdown blog articles through the user's article API, using local credentials, api.http, and the blog article structure file.
metadata:
  short-description: Publish local blog drafts through API
---

# Blog Article Publisher

Use this skill when the user wants to send a local Markdown article to their blog API, update an existing draft, or change an article's sources, topics, or tags.

## Local Files

Expect the current working directory to contain:

- Markdown article files (`*.md`).
- `credentials`, containing the real API base URL and tokens.
- `api.http`, documenting the current API endpoints.
- `ESTRUCTURA_Contenido_Articulo_IA.md`, documenting the required article format.

Never copy credentials into the skill, article files, shell output, or final messages. Read credentials only when needed to make the API request, and avoid printing token values.

Use the read token (`apiToken`, `api_token`, or `token`) for portal lookups. Use the write token (`aiToken` or `ai_token`) only for draft creation, draft updates, and association changes.

If `api.http` or `ESTRUCTURA_Contenido_Articulo_IA.md` is present, prefer those local files over this skill's summary because they may be newer.

## Behavior

Before sending or updating an article, ask which article to use when the user has not named one. Prefer listing available `*.md` files from the current directory.

The API creates or updates drafts through `/ai/drafts`; it does not publish directly to the public site. If the user says "publicar", treat that as sending the article as a draft for editor review unless the local API contract shows a real publish endpoint.

Use the helper script for routine calls:

```bash
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py draft "article.md"
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py draft "article.md" --update --slug article-slug
```

For taxonomy/source changes, use association endpoints instead of replacing the full draft unless the user explicitly asks to update the article body too:

```bash
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py topics article-slug tema-1 "Tema nuevo"
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py tags article-slug tag-1 tag-2
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py sources article-slug --sources-json '[{"source_id":1,"reference":"CIC 1440","quote":"..."}]'
```

Use `--dry-run` to inspect the request payload before network calls when debugging or when the user asks for review first.

Use authenticated reads to resolve existing slugs and ids before sending:

```bash
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py catalog sections topics tags sources series
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py read topics
python ~/.codex/skills/blog-article-publisher/scripts/blog_article_api.py read articles/article-slug
```

If `credentials` provides `domain_prod` instead of `baseUrl`, the helper treats it as the portal domain and appends `/api/v1`.

## Article Parsing

The local article Markdown format maps to the API payload as follows:

- First `#` heading: `title`.
- `## Metadatos`: bullet keys such as `excerpt`, `section`, `level`, `content_type`, `seo_title`, `seo_description`, and `ai_notes`.
- `## Topics`: topic slugs or names, one per bullet.
- `## Tags`: tag slugs or names, one per bullet.
- `## Fuentes`: numbered entries using `source_id`, `reference`, `quote`, and optional `context_note`.
- `## Contenido`: everything after this heading, until `## Fuentes` if present, becomes `content`.

When a topic or tag line includes notes such as `verificar existencia`, do not silently treat it as confirmed taxonomy for the draft endpoint. Ask whether to omit it from the draft payload or attach it afterward with the association endpoint, which can create missing topics/tags according to `api.http`.

When source lines contain `source_id: PENDIENTE`, omit those source entries from the API payload and tell the user that source ids still need editorial confirmation before they can be attached.

When the read token can access catalog endpoints, use it to resolve real topic/tag slugs and source ids. Do not guess ids.

## References

Read [references/article-structure.md](references/article-structure.md) when generating, repairing, or validating local article Markdown before sending it.

Read [references/api-contract.md](references/api-contract.md) before constructing API requests if endpoint behavior, payload shape, or update semantics matter.
