#!/usr/bin/env python3
"""Send a local .txt petition + cover image to the voz-ciudadana Petitions API.

The API always creates petitions with status "draft" — there is no way to
auto-publish, by design. A human admin reviews and flips status to "open"
from the admin panel.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import re
import sys
import urllib.error
import urllib.request
import uuid
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
    return value


# --- .txt petition parsing -------------------------------------------------

LETTER_HEADING = "CARTA DEL ADHERENTE"
EMAILS_LINE_RE = re.compile(r"^\s*Correos\s*:\s*(.+)$", re.IGNORECASE)
EMAIL_RE = re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")


def parse_petition_txt(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8").strip("\n")
    lines = text.splitlines()
    if not lines:
        raise SystemExit(f"empty petition file: {path}")

    title = lines[0].strip()

    letter_match = re.search(rf"^{LETTER_HEADING}\s*$", text, flags=re.MULTILINE)
    if not letter_match:
        raise SystemExit(f"no '{LETTER_HEADING}' section found in {path}")

    description = text[len(title) : letter_match.start()].strip()
    letter_and_rest = text[letter_match.end() :].strip()

    emails: list[str] = []
    for line in letter_and_rest.splitlines():
        line_match = EMAILS_LINE_RE.match(line)
        if line_match:
            emails = EMAIL_RE.findall(line_match.group(1))
            break

    if emails:
        # Strip the trailing "Correos: ..." line out of the letter body.
        letter = re.sub(
            r"\n?" + re.escape(next(line for line in letter_and_rest.splitlines() if EMAILS_LINE_RE.match(line))),
            "",
            letter_and_rest,
        ).strip()
    else:
        letter = letter_and_rest

    result: dict[str, str] = {
        "title": title,
        "description": description,
        "letter": letter,
    }
    if emails:
        result["email"] = emails[0]
    if len(emails) > 1:
        result["email_cc"] = emails[1]
    result["excerpt"] = generate_excerpt(description)
    return result


def generate_excerpt(description: str) -> str:
    """First paragraph, cut at the first or second sentence-ending period."""
    first_paragraph = description.split("\n", 1)[0].strip()
    if not first_paragraph:
        return ""

    two_sentences = re.match(r"\s*(.+?[.!?])\s+(.+?[.!?])", first_paragraph)
    if two_sentences:
        return f"{two_sentences.group(1)} {two_sentences.group(2)}".strip()

    one_sentence = re.match(r"\s*(.+?[.!?])", first_paragraph)
    if one_sentence:
        return one_sentence.group(1).strip()

    return first_paragraph


# --- HTTP helpers ------------------------------------------------------------


def request_json(method: str, url: str, token: str | None, payload: object | None, dry_run: bool) -> dict:
    body = json.dumps(payload, ensure_ascii=False).encode("utf-8") if payload is not None else None
    if dry_run:
        print(f"{method} {url}")
        if payload is not None:
            print(json.dumps(payload, ensure_ascii=False, indent=2))
        return {}

    request = urllib.request.Request(url, data=body, method=method)
    if token:
        request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Accept", "application/json")
    if body is not None:
        request.add_header("Content-Type", "application/json")

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            text = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {exc.code}: {detail}") from exc

    return json.loads(text) if text else {}


def build_multipart(fields: dict[str, str], file_field: str, file_path: Path) -> tuple[bytes, str]:
    boundary = uuid.uuid4().hex
    parts: list[bytes] = []

    for name, value in fields.items():
        parts.append(
            (
                f"--{boundary}\r\n"
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'
                f"{value}\r\n"
            ).encode("utf-8")
        )

    mime_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    parts.append(
        (
            f"--{boundary}\r\n"
            f'Content-Disposition: form-data; name="{file_field}"; filename="{file_path.name}"\r\n'
            f"Content-Type: {mime_type}\r\n\r\n"
        ).encode("utf-8")
    )
    parts.append(file_path.read_bytes())
    parts.append(b"\r\n")
    parts.append(f"--{boundary}--\r\n".encode("utf-8"))

    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def request_multipart(url: str, token: str, fields: dict[str, str], file_field: str, file_path: Path, dry_run: bool) -> dict:
    if dry_run:
        print(f"POST {url}")
        print(json.dumps({**fields, file_field: f"<file:{file_path}>"}, ensure_ascii=False, indent=2))
        return {}

    body, content_type = build_multipart(fields, file_field, file_path)
    request = urllib.request.Request(url, data=body, method="POST")
    request.add_header("Authorization", f"Bearer {token}")
    request.add_header("Accept", "application/json")
    request.add_header("Content-Type", content_type)

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            text = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"HTTP {exc.code}: {detail}") from exc

    return json.loads(text) if text else {}


# --- auth --------------------------------------------------------------------
#
# The API no longer expects a per-run email/password login. Instead, an
# operator runs `php artisan petitions:api-token <email>` once on the server
# to mint a long-lived Sanctum token scoped to ["petitions:create",
# "categories:read"], and hands that token to this script via the
# VOZ_CIUDADANA_API_TOKEN env var or the `token`/`apiToken` key in the
# credentials file.


def load_auth(args: argparse.Namespace) -> tuple[str, str]:
    values = parse_key_values(Path(args.credentials)) if Path(args.credentials).exists() else {}
    base_url = args.base_url or pick(values, "baseUrl", "base_url", "APP_URL", "url")
    token = (
        args.token
        or os.environ.get("VOZ_CIUDADANA_API_TOKEN")
        or pick(values, "token", "apiToken", "api_token", "VOZ_CIUDADANA_API_TOKEN")
    )
    if not base_url:
        raise SystemExit("Missing baseUrl/APP_URL in credentials or --base-url")
    if not token:
        raise SystemExit(
            "Missing API token. Set VOZ_CIUDADANA_API_TOKEN, pass --token, or add "
            "'token=...' to the credentials file. Generate one on the server with: "
            "php artisan petitions:api-token <email>"
        )
    return normalize_base_url(base_url), token


# --- CLI -----------------------------------------------------------------


def add_common(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--credentials", default="credentials")
    parser.add_argument("--base-url")
    parser.add_argument("--token", help="API token (overrides VOZ_CIUDADANA_API_TOKEN and credentials file)")
    parser.add_argument("--dry-run", action="store_true")


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    parse_cmd = subparsers.add_parser("parse", help="Parse a petition .txt and print the resulting payload")
    parse_cmd.add_argument("txt_file")

    categories = subparsers.add_parser("categories", help="List available categories")
    add_common(categories)

    submit = subparsers.add_parser("submit", help="Create a draft petition from a .txt file + image")
    add_common(submit)
    submit.add_argument("txt_file")
    submit.add_argument("image")
    submit.add_argument("--category-id", type=int, required=True)
    submit.add_argument("--goal", type=int, default=1500, help="default 1500")
    submit.add_argument("--email-cc")
    submit.add_argument("--excerpt", help="overrides the auto-generated excerpt")
    submit.add_argument(
        "--email-body",
        help="raw text to send as-is in email_body (e.g. the post-signature thank-you email); "
        "the skill does not author this content, only forwards it",
    )
    submit.add_argument(
        "--whatsapp-petition",
        help="raw text to send as-is in whatsapp_petition (wa.me-style share text); "
        "the skill does not author this content, only forwards it",
    )

    args = parser.parse_args()

    if args.command == "parse":
        payload = parse_petition_txt(Path(args.txt_file))
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0

    if args.command == "categories":
        base_url, token = load_auth(args)
        result = request_json("GET", f"{base_url}/api/categories", token, None, args.dry_run)
        if result:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    if args.command == "submit":
        base_url, token = load_auth(args)

        payload = parse_petition_txt(Path(args.txt_file))
        image_path = Path(args.image)
        if not args.dry_run and not image_path.exists():
            raise SystemExit(f"image not found: {image_path}")

        fields = {
            "title": payload["title"],
            "description": payload["description"],
            "letter": payload["letter"],
            "email": payload.get("email", ""),
            "category_id": str(args.category_id),
            "goal": str(args.goal),
            "excerpt": args.excerpt or payload["excerpt"],
        }
        if not fields["email"]:
            raise SystemExit("Could not find a recipient email in the .txt (expected a 'Correos:' line)")

        email_cc = args.email_cc or payload.get("email_cc")
        if email_cc:
            fields["email_cc"] = email_cc
        if args.email_body:
            fields["email_body"] = args.email_body
        if args.whatsapp_petition:
            fields["whatsapp_petition"] = args.whatsapp_petition

        result = request_multipart(
            f"{base_url}/api/petitions",
            token,
            fields,
            "imagen",
            image_path,
            args.dry_run,
        )
        if result:
            print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
