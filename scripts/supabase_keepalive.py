#!/usr/bin/env python3
"""Ping a Supabase project through the REST API.

Environment variables:
  SUPABASE_URL: project URL, for example https://xxxxx.supabase.co
  SUPABASE_ANON_KEY: publishable/anon key with minimal read access
  SUPABASE_KEEPALIVE_TABLE: table to query, default "keepalive"
  SUPABASE_KEEPALIVE_SCHEMA: schema name, default "public"
"""

from __future__ import annotations

import json
import os
import sys
import time
from datetime import datetime, timezone
import urllib.error
import urllib.parse
import urllib.request


def getenv_required(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        print(f"Missing required environment variable: {name}", file=sys.stderr)
        sys.exit(2)
    return value


def build_url(base_url: str, table: str) -> str:
    clean_base = base_url.rstrip("/")
    encoded_table = urllib.parse.quote(table, safe="")
    query = urllib.parse.urlencode({"id": "eq.true", "select": "id,checked_at"})
    return f"{clean_base}/rest/v1/{encoded_table}?{query}"


def request_once(url: str, anon_key: str, schema: str) -> tuple[int, str]:
    payload = json.dumps(
        {"checked_at": datetime.now(timezone.utc).isoformat()}
    ).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=payload,
        headers={
            "apikey": anon_key,
            "Authorization": f"Bearer {anon_key}",
            "Accept": "application/json",
            "Accept-Profile": schema,
            "Content-Profile": schema,
            "Content-Type": "application/json",
            "Prefer": "return=representation",
        },
        method="PATCH",
    )

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = response.read().decode("utf-8", errors="replace")
            return response.status, body
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        return error.code, body
    except urllib.error.URLError as error:
        return 0, str(error.reason)


def main() -> int:
    supabase_url = getenv_required("SUPABASE_URL")
    anon_key = getenv_required("SUPABASE_ANON_KEY")
    table = os.getenv("SUPABASE_KEEPALIVE_TABLE", "keepalive").strip() or "keepalive"
    schema = os.getenv("SUPABASE_KEEPALIVE_SCHEMA", "public").strip() or "public"
    url = build_url(supabase_url, table)

    max_attempts = 3
    for attempt in range(1, max_attempts + 1):
        status, body = request_once(url, anon_key, schema)
        if 200 <= status < 300:
            try:
                rows = json.loads(body)
            except json.JSONDecodeError:
                rows = None

            if isinstance(rows, list) and len(rows) == 1:
                checked_at = rows[0].get("checked_at", "unknown")
                print(
                    f"Supabase keepalive OK: status={status}, "
                    f"table={schema}.{table}, checked_at={checked_at}"
                )
                return 0

            body = f"Expected exactly one updated row, received: {body[:500]}"

        print(
            f"Supabase keepalive failed: attempt={attempt}/{max_attempts}, "
            f"status={status}, table={schema}.{table}, response={body[:500]}",
            file=sys.stderr,
        )

        if attempt < max_attempts:
            time.sleep(5 * attempt)

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
