#!/usr/bin/env python3
"""Send local Markdown articles to the blog article API."""

from __future__ import annotations

import argparse
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def parse_key_values(path: Path) -> dict[str, str]:
    if not path.exists():
        raise SystemExit(f"credentials file not found: {path}")

    raw = path.read_text(encoding="utf-8").strip()
    if raw.startswith("{"):
        data = json.loads(raw)
        return {str(k): str(v) for k, v in data.items() if v is not None}

    values: dict[str, str] = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("//"):
            continue
        match = re.match(r"@?([A-Za-z0-9_.-]+)\s*(?:=|:)\s*(.*)$", line)
        if not match:
            continue
        key, value = match.groups()
        values[key] = value.strip().strip('"').strip("'")
    return values


def pick(values: dict[str, str], *keys: str) -> str | None:
    lowered = {key.lower(): value for key, value in values.items()}
    for key in keys:
        value = values.get(key) or lowered.get(key.lower())
        if value:
            return value
    return None


def normalize_base_url(value: str) -> str:
    value = value.strip().rstrip("/")
    if not re.match(r"^https?://", value):
        value = "https://" + value
    parsed = urllib.parse.urlparse(value)
    if "/api/" not in parsed.path:
        value += "/api/v1"
    return value.rstrip("/")


def slugify(text: str) -> str:
    replacements = {
        "á": "a",
        "é": "e",
        "í": "i",
        "ó": "o",
        "ú": "u",
        "ü": "u",
        "ñ": "n",
    }
    value = text.strip().lower()
    for src, dst in replacements.items():
        value = value.replace(src, dst)
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return re.sub(r"-{2,}", "-", value).strip("-")


def find_heading(text: str, heading: str) -> re.Match[str] | None:
    return re.search(rf"^##\s+{re.escape(heading)}\s*$", text, flags=re.MULTILINE | re.IGNORECASE)


def section_block(text: str, heading: str) -> str:
    match = find_heading(text, heading)
    if not match:
        return ""
    start = match.end()
    next_match = re.search(r"^##\s+", text[start:], flags=re.MULTILINE)
    end = start + next_match.start() if next_match else len(text)
    return text[start:end].strip()


def content_block(text: str) -> str:
    match = find_heading(text, "Contenido")
    if not match:
        return ""
    start = match.end()
    sources = find_heading(text[start:], "Fuentes")
    end = start + sources.start() if sources else len(text)
    return text[start:end].strip()


def parse_bullets(block: str) -> list[str]:
    items: list[str] = []
    for line in block.splitlines():
        match = re.match(r"\s*[-*]\s+(.+?)\s*$", line)
        if match:
            items.append(match.group(1).strip())
    return items


def parse_metadata(block: str) -> dict[str, str]:
    metadata: dict[str, str] = {}
    for item in parse_bullets(block):
        if ":" not in item:
            continue
        key, value = item.split(":", 1)
        metadata[key.strip()] = value.strip()
    return metadata


def clean_taxonomy(items: list[str], include_unverified: bool) -> list[str]:
    cleaned: list[str] = []
    for item in items:
        value = item.split(" — ", 1)[0].strip()
        if not include_unverified and "verificar" in item.lower():
            continue
        if value and value not in {"—", "-"}:
            cleaned.append(value)
    return cleaned


def parse_source_entry(entry: str) -> dict[str, object]:
    source: dict[str, object] = {}
    parts = [part.strip() for part in re.split(r"\s+—\s+", entry)]
    for part in parts:
        if ":" not in part:
            continue
        key, value = part.split(":", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key == "source_id":
            if not value.isdigit():
                return {}
            source[key] = int(value)
        elif key in {"reference", "quote", "context_note", "type", "title"}:
            source[key] = value
    return source


def parse_sources(block: str) -> list[dict[str, object]]:
    sources: list[dict[str, object]] = []
    for line in block.splitlines():
        match = re.match(r"\s*(?:[-*]|\d+[.)])\s+(.+?)\s*$", line)
        if not match:
            continue
        source = parse_source_entry(match.group(1))
        if source:
            sources.append(source)
    return sources


def parse_article(path: Path, include_unverified_taxonomy: bool) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    title_match = re.search(r"^#\s+(.+?)\s*$", text, flags=re.MULTILINE)
    if not title_match:
        raise SystemExit(f"No H1 title found in {path}")

    metadata = parse_metadata(section_block(text, "Metadatos"))
    content = content_block(text)
    if not content:
        raise SystemExit(f"No '## Contenido' section found in {path}")

    payload: dict[str, object] = {
        "title": title_match.group(1).strip(),
        "content": content,
    }
    for key in [
        "excerpt",
        "section",
        "level",
        "content_type",
        "seo_title",
        "seo_description",
        "ai_notes",
    ]:
        if metadata.get(key):
            payload[key] = metadata[key]

    topics = clean_taxonomy(parse_bullets(section_block(text, "Topics")), include_unverified_taxonomy)
    tags = clean_taxonomy(parse_bullets(section_block(text, "Tags")), include_unverified_taxonomy)
    sources = parse_sources(section_block(text, "Fuentes"))
    if topics:
        payload["topics"] = topics
    if tags:
        payload["tags"] = tags
    if sources:
        payload["sources"] = sources
    return payload


def request_json(method: str, url: str, token: str, payload: object | None, dry_run: bool) -> None:
    body = json.dumps(payload, ensure_ascii=False, indent=2) if payload is not None else None
    if dry_run:
        print(f"{method} {url}")
        if body is not None:
            print(body)
        return

    data = body.encode("utf-8") if body is not None else None
    request = urllib.request.Request(url, data=data, method=method)
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Accept", "application/json")
    if data is not None:
        request.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            print(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {exc.code}: {detail}") from exc


def load_write_auth(args: argparse.Namespace) -> tuple[str, str]:
    values = parse_key_values(Path(args.credentials))
    base_url = args.base_url or pick(
        values,
        "baseUrl",
        "base_url",
        "BASE_URL",
        "BLOG_BASE_URL",
        "domain_prod",
        "domain",
        "url",
    )
    token = args.ai_token or pick(values, "aiToken", "ai_token", "AI_TOKEN", "BLOG_AI_TOKEN", "ARTICLE_DRAFT_TOKEN")
    if not base_url:
        raise SystemExit("Missing baseUrl/domain_prod in credentials or --base-url")
    if not token:
        raise SystemExit("Missing aiToken in credentials or --ai-token")
    return normalize_base_url(base_url), token


def load_read_auth(args: argparse.Namespace) -> tuple[str, str]:
    values = parse_key_values(Path(args.credentials))
    base_url = args.base_url or pick(
        values,
        "baseUrl",
        "base_url",
        "BASE_URL",
        "BLOG_BASE_URL",
        "domain_prod",
        "domain",
        "url",
    )
    token = args.api_token or pick(values, "apiToken", "api_token", "API_TOKEN", "BLOG_API_TOKEN", "token")
    if not base_url:
        raise SystemExit("Missing baseUrl/domain_prod in credentials or --base-url")
    if not token:
        raise SystemExit("Missing apiToken/token in credentials or --api-token")
    return normalize_base_url(base_url), token


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--credentials", default="credentials")
    parser.add_argument("--base-url")
    parser.add_argument("--ai-token")
    parser.add_argument("--api-token")
    parser.add_argument("--dry-run", action="store_true")


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    draft = subparsers.add_parser("draft", help="Create or replace an article draft")
    add_common(draft)
    draft.add_argument("article")
    draft.add_argument("--slug", help="Required for --update; defaults to slugified title")
    draft.add_argument("--update", action="store_true")
    draft.add_argument("--include-unverified-taxonomy", action="store_true")

    topics = subparsers.add_parser("topics", help="Add or remove topics")
    add_common(topics)
    topics.add_argument("slug")
    topics.add_argument("topics", nargs="+")
    topics.add_argument("--remove", action="store_true")

    tags = subparsers.add_parser("tags", help="Add or remove tags")
    add_common(tags)
    tags.add_argument("slug")
    tags.add_argument("tags", nargs="+")
    tags.add_argument("--remove", action="store_true")

    sources = subparsers.add_parser("sources", help="Add or remove sources")
    add_common(sources)
    sources.add_argument("slug")
    sources.add_argument("--sources-json", help="JSON array of sources to add")
    sources.add_argument("--remove-id", type=int, help="Source id to remove")

    read = subparsers.add_parser("read", help="GET a read endpoint using apiToken/token")
    add_common(read)
    read.add_argument("path", help="Endpoint path such as topics, sections, sources, or articles/slug")

    catalog = subparsers.add_parser("catalog", help="GET common catalog endpoints")
    add_common(catalog)
    catalog.add_argument(
        "resources",
        nargs="*",
        default=["sections", "topics", "tags", "sources", "series"],
        help="Resources to fetch; defaults to sections topics tags sources series",
    )

    args = parser.parse_args()

    if args.command == "draft":
        base_url, token = load_write_auth(args)
        payload = parse_article(Path(args.article), args.include_unverified_taxonomy)
        slug = args.slug or slugify(str(payload["title"]))
        if args.update:
            request_json("PUT", f"{base_url}/ai/drafts/{slug}", token, payload, args.dry_run)
        else:
            request_json("POST", f"{base_url}/ai/drafts", token, payload, args.dry_run)
        return 0

    if args.command in {"topics", "tags"}:
        base_url, token = load_write_auth(args)
        values = getattr(args, args.command)
        endpoint = f"{base_url}/ai/articles/{args.slug}/{args.command}"
        if args.remove:
            for value in values:
                quoted = urllib.parse.quote(value, safe="")
                request_json("DELETE", f"{endpoint}/{quoted}", token, None, args.dry_run)
        else:
            request_json("POST", endpoint, token, {args.command: values}, args.dry_run)
        return 0

    if args.command == "sources":
        base_url, token = load_write_auth(args)
        endpoint = f"{base_url}/ai/articles/{args.slug}/sources"
        if args.remove_id is not None:
            request_json("DELETE", f"{endpoint}/{args.remove_id}", token, None, args.dry_run)
        elif args.sources_json:
            request_json("POST", endpoint, token, {"sources": json.loads(args.sources_json)}, args.dry_run)
        else:
            raise SystemExit("Use --sources-json or --remove-id")
        return 0

    if args.command == "read":
        base_url, token = load_read_auth(args)
        path = args.path.strip("/")
        request_json("GET", f"{base_url}/{path}", token, None, args.dry_run)
        return 0

    if args.command == "catalog":
        base_url, token = load_read_auth(args)
        for resource in args.resources:
            path = resource.strip("/")
            print(f"\n# GET /{path}", file=sys.stderr)
            request_json("GET", f"{base_url}/{path}", token, None, args.dry_run)
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
