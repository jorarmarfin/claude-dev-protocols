# Blog Article API Contract

This summary is based on the user's local `api.http`. If the current project has an `api.http`, prefer that file over this reference.

## Authentication

Private write endpoints require:

```http
Authorization: Bearer {aiToken}
Content-Type: application/json
Accept: application/json
```

Read `baseUrl` or `domain_prod` from the local `credentials` file. Do not print token values.

Use `apiToken`, `api_token`, or `token` for read endpoints:

- `GET /articles`
- `GET /articles/{slug}`
- `GET /sections`
- `GET /topics`
- `GET /series`
- `GET /search?q=...`
- `GET /tags/{slug}/articles`

If the portal exposes `GET /tags` or `GET /sources`, use those to resolve tag slugs and source ids. If they return 404, fall back to article detail/search results or ask the user for the source id.

Use `aiToken` or `ai_token` for private write endpoints.

## Drafts

Create a draft:

```http
POST {baseUrl}/ai/drafts
```

Update an existing draft:

```http
PUT {baseUrl}/ai/drafts/{slug}
```

Both endpoints accept a complete article payload:

```json
{
  "title": "Article title",
  "excerpt": "Short excerpt",
  "content": "Markdown content",
  "section": "apologetica",
  "level": "basic",
  "content_type": "article",
  "topics": ["topic-slug"],
  "tags": ["tag-slug"],
  "sources": [
    {
      "source_id": 1,
      "reference": "CIC 1440",
      "quote": "...",
      "context_note": "..."
    }
  ],
  "seo_title": "SEO title",
  "seo_description": "SEO description",
  "ai_notes": "Editorial notes"
}
```

Rules from the local docs:

- Draft endpoints always create or edit drafts, never published articles.
- `ai_assisted=true` is handled by the API.
- `section` must already exist (by slug); an unknown section returns `422`.
- `topics` and `tags` no longer need to exist beforehand: the draft endpoints resolve each entry by slug and auto-create it (name + slug) when missing, the same way the association endpoints do. Sending a slug or a plain name both work.
- `series` is not accepted in the JSON; mention series suggestions in `ai_notes`.
- `status`, `is_featured`, `published_at`, `author_id`, and `review_notes` are ignored if sent.
- Updating a draft replaces the full article content.
- Updating published or archived articles returns `409`.

## Topics

Add topics:

```http
POST {baseUrl}/ai/articles/{slug}/topics
```

Payload:

```json
{ "topics": ["eucaristia", "Un tema nuevo"] }
```

Remove one topic:

```http
DELETE {baseUrl}/ai/articles/{slug}/topics/{topic}
```

The association endpoint creates missing topics by name/slug, same as the draft endpoints. Use it to add/remove topics on an already-published or non-draft article, or when only touching taxonomy without resending the full article body.

## Tags

Add tags:

```http
POST {baseUrl}/ai/articles/{slug}/tags
```

Payload:

```json
{ "tags": ["principiantes", "Otra etiqueta"] }
```

Remove one tag:

```http
DELETE {baseUrl}/ai/articles/{slug}/tags/{tag}
```

The association endpoint creates missing tags by name/slug, same as the draft endpoints. Use it to add/remove tags on an already-published or non-draft article, or when only touching taxonomy without resending the full article body.

## Sources

Add sources:

```http
POST {baseUrl}/ai/articles/{slug}/sources
```

Payload:

```json
{
  "sources": [
    { "source_id": 1, "reference": "CIC 1440", "quote": "..." },
    { "type": "catechism", "title": "Catecismo de la Iglesia Católica", "reference": "CIC 1441" }
  ]
}
```

Remove a source by source id:

```http
DELETE {baseUrl}/ai/articles/{slug}/sources/{source_id}
```

For a new source, `type` and `title` are required.
